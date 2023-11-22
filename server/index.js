const express = require("express");
const cors = require("cors");
const database = require("./database.js");

const app = express();
const db = new database();
app.use(cors());
app.use(express.json());

app.get("/init", (req, res) =>
	db.handleFileExecute(res, "init", "cs4400_phase3_tables_data.sql")
);

app.get("/clear", (req, res) =>
	db.handleFileExecute(res, "clear", "cs4400_phase3_empty_tables_data.sql")
);

app.get("/get/:table/:attribute?", (req, res) => {
	const { table, item } = req.params;
	if (item) db.queryDB(table, item, req, res);
	else db.viewDB(table, res);
});

app.post("/:procedure?", (req, res) => {
	const { procedure } = req.params;
	db.modifyDB(procedure, req, res);
});

app.listen(3001, () => {
	console.log("Server started on port 3001");
});
