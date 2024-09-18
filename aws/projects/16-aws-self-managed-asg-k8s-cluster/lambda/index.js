const { Client } = require('ssh2');
const fs = require('fs');
const path = require('path');

exports.handler = async (event) => {
    return new Promise((resolve, reject) => {
        const conn = new Client();
        const bastionHost = process.env.BASTION_HOST;
        const sshUser = process.env.SSH_USER;

        // Path to private key in Lambda deployment package
        const privateKeyPath = path.join(__dirname, 'k8_ssh_key.pem');
        const privateKey = fs.readFileSync(privateKeyPath, 'utf8');

        conn.on('ready', () => {
            console.log('SSH connection ready');
            conn.exec('ansible-playbook -i /home/ubuntu/inventory /home/ubuntu/ansible/play.yml', (err, stream) => {
                if (err) {
                    console.error('Error executing Ansible playbook:', err);
                    conn.end();
                    reject(err);
                    return;
                }

                let stdout = '';
                let stderr = '';

                stream.on('close', (code, signal) => {
                    console.log(`Ansible playbook execution completed with code ${code}`);
                    conn.end();
                    if (code === 0) {
                        resolve('Ansible playbook executed successfully');
                    } else {
                        reject(`Ansible playbook failed with code ${code}`);
                    }
                }).on('data', (data) => {
                    stdout += data;
                    console.log('STDOUT: ' + data);
                }).stderr.on('data', (data) => {
                    stderr += data;
                    console.error('STDERR: ' + data);
                });
            });
        }).connect({
            host: bastionHost,
            port: 22,
            username: sshUser,
            privateKey: privateKey
        });
    });
};
