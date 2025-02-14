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
            FULL_PATH="/home/\${USERNAME}/domains/\${USERNAME}.serv00.net/logs"
            cd "\$FULL_PATH"
            ps aux | grep '[r]un -c con' | awk '{print $2}' | xargs -r kill -9 > /dev/null 2>&1
           sbb="\$(cat sb.txt)"
           nohup ./"\$sbb" run -c config.json >/dev/null 2>&1 &
          sleep 3
          echo '重启成功'
`;
      exec(additionalCommands, (err, stdout, stderr) => {
        if (err) {
            console.error(`路径验证失败: ${stderr}`);
            return res.status(404).send(stderr);
        }
        res.type('text').send(stdout);
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
