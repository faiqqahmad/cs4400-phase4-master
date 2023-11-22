import Head from "next/head";
import DataTable from "@/components/DataTable";
import { queryDB } from "@/helpers/database";

export default function View({ viewName, viewData }) {
	return (
		<div className="pageContainer">
			<Head>
				<title>{viewName}</title>
				<link rel="icon" href="/favicon.ico" />
			</Head>

			<div className="text-center" style={{ marginBottom: "15px" }}>
				{viewName}
			</div>

			<DataTable data={viewData} />
		</div>
	);
}

export async function getStaticProps({ params }) {
	const viewName = params.viewName.replace(/\-/g, "+");

	// get results from MySQL database
	const viewData = await queryDB(viewName);

	return {
		props: {
			viewName,
			viewData,
		},
	};
}

export async function getStaticPaths() {
	const views = require("@/helpers/databaseInfo.json").views;

	return {
		paths: views.map((view) => ({
			params: {
				viewName: view.toLowerCase().replace(/ /g, "-"),
			},
		})),
		fallback: false,
	};
}
