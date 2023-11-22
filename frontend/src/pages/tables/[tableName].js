import Head from "next/head";
import DataTable from "@/components/DataTable";
import { queryDB } from "@/helpers/database.js";

export default function Table({ tableName, tableData }) {
	return (
		<div className="pageContainer">
			<Head>
				<title>{tableName}</title>
				<link rel="icon" href="/favicon.ico" />
			</Head>

			<div className="text-center" style={{ marginBottom: "15px" }}>
				{tableName}
			</div>

			<DataTable data={tableData} />
		</div>
	);
}

export async function getStaticProps({ params }) {
	const tableName = params.tableName.replace(/\-/g, "+");

	// get results from MySQL database
	const tableData = await queryDB(tableName);
	
	return {
		props: {
			tableName,
			tableData,
		},
	};
}

export async function getStaticPaths() {
	const tables = require("@/helpers/databaseInfo.json").tables;

	return {
		paths: tables.map((table) => ({
			params: {
				tableName: table.toLowerCase().replace(/ /g, "-"),
			},
		})),
		fallback: false,
	};
}
