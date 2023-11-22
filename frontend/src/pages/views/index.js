import Head from "next/head";
import ButtonTable from "@/components/ButtonTable";

export default function Index() {
	return (
		<div>
			<Head>
				<title>Tables</title>
				<link rel="icon" href="/favicon.ico" />
			</Head>

			<ButtonTable type = "views"/>
		</div>
	);
}
