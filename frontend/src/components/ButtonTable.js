import databaseInfo from "@/helpers/databaseInfo";
import { useRouter } from "next/router"; 
import Link from "next/link";

const ButtonTable = (props) => {
	const { asPath } = useRouter();

	return (
		<div className="container">
			{databaseInfo[props.type].map((table, index) => (
				<Link href={`${asPath}/${table}`} key={index} className="button">
					{table}
				</Link>
			))}
		</div>
	)
};

export default ButtonTable;
