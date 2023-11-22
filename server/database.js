const mysql = require("mysql");
const fs = require("fs");

class Database {
	constructor() {
		this.connection = mysql.createConnection({
			host: "localhost",
			user: "root",
			password: "password",
			database: "flight_management",
			multipleStatements: true,
		});

		// initialize database with tables and procedures
		runSQLFile(this.connection, "cs4400_phase3_tables_data.sql")
			.then(() =>
				runSQLFile(
					this.connection,
					"cs4400_phase3_stored_procedures_team33.sql"
				)
			)
			.then(() => console.log("database initialized"));
	}

	async handleFileExecute(res, action, filename) {
		try {
			await runSQLFile(this.connection, filename);
			await runSQLFile(this.connection, "cs4400_phase3_stored_procedures_team33.sql");
			const message = `Database ${
				action == "init" ? "reset to test values" : "cleared"
			}`;
			res.json(message);
		} catch (err) {
			res.status(400).json({ error: err });
		}
	}

	async callDB(query, vals, res) {
		this.connection.query(query, vals, (err, result) =>
			handleResponse(err, result, res)
		);
	}

	async modifyDB(query, req, res) {
		const vals = Object.values(req.body);
		this.callDB(
			`call ${query}(${"?,".repeat(vals.length).slice(0, -1)})`,
			Object.values(req.body),
			res
		);
	}

	async queryDB(table, item, req, res) {
		this.callDB(`select ${item} from ${table}`, res);
	}

	async viewDB(view, res) {
		this.connection.query(`select * from ${view}`, (err, result) =>
			handleResponse(err, result, res)
		);
	}
}

async function runSQLFile(connection, filename) {
	const sql = fs
		.readFileSync(`./sqlFiles/${filename}`)
		.toString()
		.replace(/DELIMITER ;?\/*/gm, "")
		.replace(/\/\//gm, ";"); // handle delimiter changes in procedures

	connection.query(sql, (err, sets, fields) => {
		if (err)
			throw new Error(JSON.stringify(err.sqlMessage ?? err, null, 2));
	});
}

async function handleResponse(err, result, res) {
	res.setHeader("Content-Type", "application/json");
	if (err) {
		console.error(err);
		res.status(400).json({ error: err });
	} else {
		res.send(result);
	}
}

module.exports = Database;
