import { runSQLFile } from "@/helpers/database";
import Head from "next/head";

export default function Index() {
	return (
		<div>
			<Head>
				<title>Tables</title>
				<link rel="icon" href="/favicon.ico" />
			</Head>

			<div className="container">
				<button className="button" onClick={() => runSQLFile("clear")}>Clear Database</button>
				<button className="button" onClick={() => runSQLFile("init")}>Reset Database To Test Values</button>
			</div>
		</div>
	);
}
