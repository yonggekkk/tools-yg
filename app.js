require('dotenv').config();
const express = require("express");
const { exec } = require('child_process');
const app = express();
app.use(express.json());

const commandToRun = "cd ~ && bash serv00keep.sh";
function runCustomCommand() {
    exec(commandToRun, function (err, stdout, stderr) {
        if (err) {
            console.log("命令执行错误: " + err);
            return;
        }
        if (stderr) {
            console.log("命令执行标准错误输出: " + stderr);
        }
        console.log("命令执行成功:\n" + stdout);
    });
}

function runAdditionalCommands() {
    const additionalCommands = `
USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
cd domains/${USERNAME}.serv00.net/logs
ps aux | grep '[r]un -c con' | awk '{print $2}' | xargs -r kill -9 > /dev/null 2>&1
sbb=$(cat sb.txt)
nohup ./"$sbb" run -c config.json >/dev/null 2>&1 &
sleep 3
cd
    `;
    exec(additionalCommands, function (err, stdout, stderr) {
        if (err) {
            console.log("命令执行错误: " + err);
            return;
        }
        if (stderr) {
            console.log("命令执行标准错误输出: " + stderr);
        }
        console.log("附加命令执行成功:\n" + stdout);
    });
}

function runlistCommands() {
    const listCommands = `
USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
cat domains/${USERNAME}.serv00.net/logs/list.txt
    `;   
    exec(listCommands, function (err, stdout, stderr) {
        if (err) {
            console.log("命令执行错误: " + err);
            return;
        }
        if (stderr) {
            console.log("命令执行标准错误输出: " + stderr);
        }
        console.log("命令执行成功:\n" + stdout);
    });
}

setInterval(runCustomCommand, 3 * 60 * 1000); // 3 minutes = 3 * 60 * 1000 ms

app.get("/up", function (req, res) {
    runCustomCommand();
    res.type("html").send("<pre>Serv00-name服务器网页保活启动：Serv00-name！UP！UP！UP！</pre>");
});

app.use((req, res, next) => {
    if (req.path === '/up') {
        return next();
    }
    if (req.path === '/re') {
        runAdditionalCommands();
        res.status(200).send('执行附加命令成功');
        return;
    }
    if (req.path === '/list') {
        runlistCommands();
        res.status(200).send('执行列表命令成功');
        return;
    }
    res.status(404).send('路径未找到');
});

app.listen(3000, () => {
    console.log("服务器已启动，监听端口 3000");
    runCustomCommand();
});
