const express = require('express');
const bcrypt = require('bcrypt');
const mysql = require('mysql2');
const jwt = require('jsonwebtoken');
const app = express();

const JWT_SECRET = 'examplejwtsecret';

const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '0227',
  database: 'mobsecfp'
});

db.connect(err => {
    if (err) throw err;
    console.log('Connected to database');
});

function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // <-- updated parsing

    if (!token) {
        return res.status(401).json({ error: 'Missing token' });
    }

    jwt.verify(token, JWT_SECRET || 'secret', (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid token' });
        }
        req.user = user;
        next();
    });
}

app.use(express.json());

app.post('/addMal', async (req, res) => {
    const { name, position, salary, password } = req.body;
    db.query(`INSERT INTO users (username, position, salary, password) VALUES ('${name}', '${position}', '${salary}', '${password}')`, async (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('Database error');
        }
        res.send('Employee added');
    });
});

app.post('/addGood', async (req, res) => {
    let { name, position, salary, password } = req.body;

    name = name?.trim();
    position = position?.trim();
    salary = parseFloat(salary);
    password = password?.trim();

    if (!name || !position || !salary || !password) {
      return res.status(400).send('Missing or invalid input');
    }

    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    db.query('INSERT INTO users (username, position, salary, password) VALUES (?, ? ,?, ?)', [name, position, salary, hashedPassword], async (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('Database error');
        }
        res.send('Employee added');
    });
});

app.post('/findEmpMal', async (req, res) => {
    const { findPassword } = req.body;
    db.query(`SELECT * FROM users WHERE password = '${findPassword}'`, async (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('Database error');
        }
        res.json(result);
    });
});

app.post('/findEmpGood', async (req, res) => {
    const { findPassword } = req.body;

    db.query('SELECT * FROM users', async (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('Database error');
        }

        let matchedUser = null;
        for (let user of result) {
            const match = await bcrypt.compare(findPassword, user.password);
            if (match) {
                matchedUser = user;
                break;
            }
        }

        if (!matchedUser) {
            return res.status(401).json({error: 'Invalid password' });
        }

        const token = jwt.sign({ user: matchedUser.username }, JWT_SECRET, { expiresIn: '1h' });

        res.json({matched: [matchedUser], token}); //need to send token as well
    });
});

app.get('/secretMal', async (req, res) => {
    res.json({ secret: 'This secret is not protected with API keys' });
});

app.get('/secretGood', authenticateToken, async (req, res) => {
    res.json({ secret: 'This secret is protected with API keys' });
});

app.listen(5000, () => {
    console.log('Server running on port 5000');
  });