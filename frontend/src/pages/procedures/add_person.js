import React from "react";
import { useState, useEffect } from "react";
import Head from "next/head";
import { useForm } from "react-hook-form";
import { CharInput, IntegerInput, SelectInput } from "@/helpers/formInputs";
import { modifyDB, queryValidOptions } from "@/helpers/database.js";
import Loading from "@/components/Loading.js";
import { handleSubmissionErrors } from "@/helpers/forms";

const selectableFields = {
	personID: { query: "person/personID", exists: false },
	locationID: { query: "location/locationID", exists: true },
	airlineID: { query: "airline/airlineID", exists: true },
	tail_num: { query: "airplane/tail_num", exists: true },
	taxID: { query: "pilot/taxID", exists: false },
};

const procedureName = "Add_Person";

export default function Add_Person() {
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
		if (isNaN(data.miles) && data.taxID == "") {
			errors.push(
				"A person must be either a passenger or pilot (miles and taxID both missing)"
			);
		}
		if (
			!(
				data.taxID != null &&
				!isNaN(data.experience) &&
				((data.flying_airline == null && data.flying_tail == null) ||
					(data.flying_airline != null && data.flying_tail != null))
			)
		) {
			errors.push(
				"A pilot must have a TaxID, experience and matching flying airplane/tail details"
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
			data.personID,
			data.first_name,
			data.last_name,
			data.locationID,
			data.taxID,
			data.experience,
			data.flying_airline,
			data.flying_tail,
			data.miles,
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
							name="personID"
							required
							maxLength={50}
							control={control}
							values={validOptions["personID"]}
							exists={selectableFields["personID"].exists}
						/>
						<CharInput
							name="first_name"
							required
							maxLength={100}
							register={register}
						/>
						<CharInput
							name="last_name"
							maxLength={100}
							register={register}
						/>
						<SelectInput
							name="locationID"
							required
							maxLength={50}
							control={control}
							values={validOptions["locationID"]}
							exists={selectableFields["locationID"].exists}
						/>
						<SelectInput
							name="taxID"
							maxLength={50}
							control={control}
							values={validOptions["taxID"]}
							exists={selectableFields["taxID"].exists}
						/>
						<IntegerInput name="experience" register={register} />
						<SelectInput
							name="flying_airline"
							maxLength={50}
							control={control}
							values={validOptions["airlineID"]}
							exists={selectableFields["airlineID"].exists}
						/>
						<SelectInput
							name="flying_tail"
							maxLength={50}
							control={control}
							values={validOptions["tail_num"]}
							exists={selectableFields["tail_num"].exists}
						/>
						<IntegerInput name="miles" register={register} />
						<input type="submit" />
					</form>
				</>
			)}
		</div>
	);
}
