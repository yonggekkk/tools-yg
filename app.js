require('dotenv').config();
const express = require("express");
const { exec } = require('child_process');
const app = express();
app.use(express.json());

const commandToRun = "cd ~ && bash serv00keep.sh";

function runCustomCommand() {
    exec(commandToRun, (err, stdout, stderr) => {
        if (err) console.error("执行错误:", err);
        else console.log("执行成功:", stdout);
    });
}

app.get("/up", (req, res) => {
    runCustomCommand();
    res.send("<pre>Serv00服务器保活已启动</pre>");
});

app.get("/re", (req, res) => {
    const additionalCommands = `
        USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
        LOG_DIR="/home/\${USERNAME}/domains/\${USERNAME}.serv00.net/logs"
        
        # Step 1 - 验证日志目录是否存在
        if [ ! -d "\${LOG_DIR}" ]; then
            echo "ERROR: 目录不存在: \${LOG_DIR}" >&2
            exit 1
        fi

        # Step 2 - 进入目录
        cd "\${LOG_DIR}" || exit 1

        # Step 3 - 终止旧进程 (静默模式)
        ps aux | grep '[r]un -c con' | awk '{print \$2}' | xargs -r kill -9 2>/dev/null

        # Step 4 - 验证sb.txt存在
        if [ ! -f "sb.txt" ]; then
            echo "ERROR: sb.txt 文件不存在于 \${LOG_DIR}" >&2
            exit 2
        fi

        # Step 5 - 读取启动文件名
        SBB_NAME=$(cat sb.txt)
        if [ -z "\${SBB_NAME}" ]; then
            echo "ERROR: sb.txt 内容为空" >&2
            exit 3
        fi

        # Step 6 - 验证可执行文件存在
        if [ ! -f "\${SBB_NAME}" ]; then
            echo "ERROR: 可执行文件不存在: \${LOG_DIR}/\${SBB_NAME}" >&2
            exit 4
        fi

        # Step 7 - 启动新进程
        nohup ./"\${SBB_NAME}" run -c config.json >/dev/null 2>&1 &
        sleep 3

        # Step 8 - 验证进程是否运行
        if ! pgrep -f "\${SBB_NAME} run -c config.json" >/dev/null; then
            echo "ERROR: 进程启动失败" >&2
            exit 5
        fi

        echo "SUCCESS: 服务已重启"
    `;
   exec(additionalCommands, (err, stdout, stderr) => {
        const result = `
[标准输出]
${stdout}

[错误输出]
${stderr}
        `.trim();

        if (err) {
            console.error(`/re 执行失败 (CODE:${err.code}):\n${result}`);
            return res.status(500).send(`<pre>重启失败:\n${result}</pre>`);
        }

        console.log(`/re 执行成功:\n${result}`);
        res.send(`<pre>重启成功:\n${result}</pre>`);
    });
});

app.get("/list", (req, res) => {
    const listCommands = `
        USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
        FULL_PATH="/home/\${USERNAME}/domains/\${USERNAME}.serv00.net/logs/list.txt"
        cat "\$FULL_PATH"
    `;
    exec(listCommands, (err, stdout, stderr) => {
        if (err) {
            console.error(`路径验证失败: ${stderr}`);
            return res.status(404).send(stderr);
        }
        res.type('text').send(stdout);
    });
});

app.use((req, res) => {
    res.status(404).send('路径未找到');
});

setInterval(runCustomCommand, 3 * 60 * 1000);

app.listen(3000, () => {
    console.log("服务器运行在端口 3000");
    runCustomCommand();
});
