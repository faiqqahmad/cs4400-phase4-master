import React from "react";
import { useState, useEffect } from "react";
import Head from "next/head";
import { useForm } from "react-hook-form";
import { CharInput, IntegerInput, SelectInput } from "@/helpers/formInputs";
import { modifyDB, queryValidOptions } from "@/helpers/database.js";
import Loading from "@/components/Loading.js";
import { handleSubmissionErrors } from "@/helpers/forms";

// use for any react-select based fields which reference other tables in the database
// the key is the name of the field in the form, and the value contains the database query to
// get all possible values for that field, with exists being a boolean indicating whether or not
// we want our form's input to be an existing value within the database (a new airplane must have a unique new tail number)
const selectableFields = {
	// queries need to match the names of the tables in the database
	airlineID: { query: "airline/airlineID", exists: true },
	tail_num: { query: "airplane/tail_num", exists: false },
	locationID: { query: "location/locationID", exists: false },
};

const procedureName = "Add_Airplane";

export default function Add_Airplane() {
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
		if (
			data.plane_type == "prop" &&
			(!data.skids || !data.props || data.jet_engines)
		)
			errors.push(
				"A prop plane must have values for skids and props, and cannot have jet engines"
			);

		if (
			data.plane_type == "jet" &&
			(!data.jet_engines || data.skids || data.props)
		) {
			errors.push(
				"A jet plane must have a value for jet engines, and cannot have skids or props"
			);
		}

		if (
			data.plane_type == "experimental" &&
			(data.jet_engines || data.skids || data.props)
		) {
			errors.push(
				"An experimental plane must have no values for jet engines, skids, or props"
			);
		}

		if (!["jet", "prop", "experimental", ""].includes(data.plane_type))
			errors.push("Plane type must be one of jet, prop, or experimental");

		// output errors if there are any and return
		if (errors.length > 0) {
			return alert(
				`Please correct the errors in the form and try again:\n${errors.join(
					"\n"
				)}`
			);
		}

		const procedureInput = [
			data.airlineID,
			data.tail_num,
			data.seat_capacity,
			data.speed,
			data.locationID,
			data.plane_type,
			data.skids,
			data.props,
			data.jet_engines,
		].map((x) => (!x ? null : x));

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
							name="airlineID"
							required
							maxLength={50}
							control={control}
							values={validOptions["airlineID"]}
							exists={selectableFields["airlineID"].exists}
						/>
						<SelectInput
							name="tail_num"
							required
							maxLength={50}
							control={control}
							values={validOptions["tail_num"]}
							exists={selectableFields["tail_num"].exists}
						/>
						<IntegerInput
							name="seat_capacity"
							min={1}
							required
							register={register}
						/>
						<IntegerInput
							name="speed"
							min={1}
							required
							register={register}
						/>
						<SelectInput
							name="locationID"
							//required
							maxLength={50}
							control={control}
							values={validOptions["locationID"]}
							exists={selectableFields["locationID"].exists}
						/>
						<CharInput
							name="plane_type"
							//required
							maxLength={100}
							register={register}
						/>
						<IntegerInput
							name="skids"
							max={1}
							register={register}
						/>
						<IntegerInput name="propellers" register={register} />
						<IntegerInput name="jet_engines" register={register} />
						<input type="submit" />
					</form>
				</>
			)}
		</div>
	);
}
