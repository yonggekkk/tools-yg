require('dotenv').config();
const express = require("express");
const { exec } = require('child_process');
const app = express();
app.use(express.json());
app.get("/info", function (req, res) {
    const commandToRun = "/bin/bash serv00keep.sh";
    exec(commandToRun, function (err, stdout, stderr) {
        if (err) {
            console.log("命令执行错误: " + err);
            res.status(500).send("服务器错误");
            return;
        }
        if (stderr) {
            console.log("命令执行标准错误输出: " + stderr);
        }
        console.log("命令执行成功:\n" + stdout);
    });

    res.type("html").send("<pre>你好啊</pre>");
});
app.use((req, res, next) => {
    if (req.path === '/info') {
        return next();
    }
    res.status(404).send('页面未找到');
});

app.listen(3000, () => {
    console.log("服务器已启动，监听端口 3000");
});
