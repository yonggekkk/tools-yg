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
    try {
        const additionalCommands = `
            USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
            LOG_DIR="/home/\${USERNAME}/domains/\${USERNAME}.serv00.net/logs"
            
            # 记录开始时间
            echo "[$(date)] 开始执行重启流程" | tee \${LOG_DIR}/restart.log

            # Step 1 - 验证目录
            if [ ! -d "\${LOG_DIR}" ]; then
                echo "ERROR: 目录不存在: \${LOG_DIR}" | tee -a \${LOG_DIR}/restart.log >&2
                exit 1
            fi

            # Step 2 - 进入目录
            cd "\${LOG_DIR}" || exit 1
            echo "当前目录: $(pwd)" | tee -a \${LOG_DIR}/restart.log

            # Step 3 - 终止旧进程
            echo "正在终止旧进程..." | tee -a \${LOG_DIR}/restart.log
            PIDS=$(ps aux | grep '[r]un -c con' | awk '{print $2}')
            if [ -z "$PIDS" ]; then
                echo "未找到运行中的进程" | tee -a \${LOG_DIR}/restart.log
            else
                kill -9 $PIDS && echo "已终止进程: $PIDS" | tee -a \${LOG_DIR}/restart.log
            fi

            # Step 4 - 验证sb.txt
            echo "正在验证sb.txt..." | tee -a \${LOG_DIR}/restart.log
            if [ ! -f "sb.txt" ]; then
                echo "ERROR: sb.txt 不存在" | tee -a \${LOG_DIR}/restart.log >&2
                exit 2
            fi
            SBB_NAME=$(cat sb.txt | tr -d '\n\r ') # 清除特殊字符
            echo "读取到可执行文件: \${SBB_NAME}" | tee -a \${LOG_DIR}/restart.log

            # Step 5 - 验证可执行文件
            if [ ! -f "\${SBB_NAME}" ]; then
                echo "ERROR: 文件不存在: $(pwd)/\${SBB_NAME}" | tee -a \${LOG_DIR}/restart.log >&2
                exit 3
            fi

            # Step 6 - 启动新进程
            echo "正在启动进程..." | tee -a \${LOG_DIR}/restart.log
            nohup ./"\${SBB_NAME}" run -c config.json > \${LOG_DIR}/nohup.out 2>&1 &
            sleep 5

            # Step 7 - 验证进程
            NEW_PID=$(pgrep -f "\${SBB_NAME} run -c config.json")
            if [ -z "$NEW_PID" ]; then
                echo "ERROR: 进程启动失败" | tee -a \${LOG_DIR}/restart.log >&2
                echo "nohup输出内容:" | tee -a \${LOG_DIR}/restart.log
                cat \${LOG_DIR}/nohup.out | tee -a \${LOG_DIR}/restart.log
                exit 4
            fi

            echo "SUCCESS: 新进程PID: $NEW_PID" | tee -a \${LOG_DIR}/restart.log
        `;

        exec(additionalCommands, (err, stdout, stderr) => {
            if (err) {
                console.error('命令执行失败:', err);
                console.error('标准错误输出:', stderr);
                console.error('标准输出:', stdout);
                return res.status(500).send(`<pre>命令执行失败:\n${stderr}\n${stdout}</pre>`);
            }
            res.send(`<pre>命令执行成功:\n${stdout}</pre>`);
        });
    } catch (err) {
        console.error('路由处理异常:', err.stack);
        res.status(500).send(`<pre>内部错误:\n${err.stack}</pre>`);
    }
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
