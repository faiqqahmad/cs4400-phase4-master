import React from "react";
import { useState, useEffect } from "react";
import Head from "next/head";
import { useForm } from "react-hook-form";
import { CharInput, IntegerInput, SelectInput } from "@/helpers/formInputs";
import { modifyDB, queryValidOptions } from "@/helpers/database.js";
import Loading from "@/components/Loading.js";
import { handleSubmissionErrors } from "@/helpers/forms";

const selectableFields = {
	// queries need to match the names of the tables in the database
	flightID: { query: "flight/flightID", exists: false },
	routeID: { query: "route/routeID", exists: true },
	airlineID: { query: "airline/airlineID", exists: true },
	tail_num: { query: "airplane/tail_num", exists: true },
};

const procedureName = "Offer_Flight";

export default function Offer_Flight() {
	const {
		handleSubmit,
		register,
		control,
		formState: { errors },
	} = useForm();

	const [data, setData] = useState(null);
	const [validOptions, setValidOptions] = useState(null);

	useEffect(() => {
		// get all possible values for selectable options (those that depend on other tables)
		const getValidOptions = async () =>
			await queryValidOptions(selectableFields);

		getValidOptions().then((validOptions) => setValidOptions(validOptions));
	}, [data]);

	// handle any submission errors that aren't handled by forms and database helpers
	const onSubmit = async (data) => {
		let errors = [];
		// may have to check if an airplane is already assigned to a specific flight 
		// before trying to assign it to this new flight
		
		if (
			(data.support_airline == null && data.support_tail != null) ||
			(data.support_airline != null && data.support_tail == null)
		) {
			errors.push(
				"support_airline and support_tail must both be real or null"
			);
		}
		if (
			data.support_airline == null &&
			data.support_tail == null &&
			(!isNaN(data.progress) ||
				data.airplane_status != null ||
				data.next_time != null)
		) {
			errors.push(
				"no assigned airplane but there is a progress, status, or next_time"
			);
		}
		if (
			data.support_airline != null &&
			data.support_tail != null &&
			(isNaN(data.progress) ||
				data.airplane_status == null ||
				data.next_time == null)
		) {
			errors.push(
				"assigned airplane but there is no progress, status, or next_time"
			);
		}
		// output errors if there are any and return
		if (errors.length > 0) {
			return alert(
				`Please correct the errors in the form and try again:\n${errors.join(
					"\n"
				)}`
			);
		}

		const procedureInput = [
			data.flightID,
			data.routeID,
			data.support_airline,
			data.support_tail,
			data.progress,
			data.airplane_status,
			data.next_time,
		].map((x) => (!x && (typeof x != "number" || isNaN(x)) ? null : x));

		// get procedure name from function name and call modifyDB
		modifyDB(procedureName.toLowerCase(), procedureInput)
			.then(() => setData(data))
			.catch((e) => alert(e.toString()));
	};

	const onError = (errors, e) => handleSubmissionErrors(errors);

	return (
		<div className="pageContainer">
			<Head>
				<title>{procedureName}</title>
				<link rel="icon" href="/favicon.ico" />
			</Head>

			<div className="text-center" style={{ marginBottom: "15px" }}>
				{procedureName}
			</div>

			{!validOptions ? (
				<Loading />
			) : (
				<>
					{data && (
						<div
							className="text-center"
							style={{ marginBottom: "15px" }}>
							Successfully called {procedureName}!
						</div>
					)}

					<form onSubmit={handleSubmit(onSubmit, onError)}>
						<SelectInput
							name="flightID"
							required
							maxLength={50}
							control={control}
							values={validOptions["flightID"]}
							exists={selectableFields["flightID"].exists}
						/>
						<SelectInput
							name="routeID"
							required
							maxLength={50}
							control={control}
							values={validOptions["routeID"]}
							exists={selectableFields["routeID"].exists}
						/>
						<SelectInput
							name="support_airline"
							//required
							maxLength={50}
							control={control}
							values={validOptions["airlineID"]}
							exists={selectableFields["airlineID"].exists}
						/>
						<SelectInput
							name="support_tail"
							//required
							maxLength={50}
							control={control}
							values={validOptions["tail_num"]}
							exists={selectableFields["tail_num"].exists}
						/>
						<IntegerInput
							name="progress"
							//required
							register={register}
						/>
						<CharInput
							name="airplane_status"
							//required
							register={register}
						/>
						<CharInput
							name="next_time"
							//required
							register={register}
						/>
						<input type="submit" />
					</form>
				</>
			)}
		</div>
	);
}
