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
    ticketID: { query: "ticket/ticketID", exists: false },
    personID: { query: "person/personID", exists: true },
    flightID: { query: "flight/flightID", exists: true },
    airportID: { query: "airport/airportID", exists: true},
};

const procedureName = "Purchase_Ticket_And_Seat";

export default function Purchase_Ticket_And_Seat() {
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
		// output errors if there are any and return
		if (errors.length > 0) {
			return alert(
				`Please correct the errors in the form and try again:\n${errors.join(
					"\n"
				)}`
			);
		}

		const procedureInput = [
			data.ticketID,
			data.cost,
            data.carrier,
            data.customer,
            data.deplane_at,
            data.seat_number,
		].map((x) => ((!x && (typeof x != "number" || isNaN(x))) ? null : x));

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
							name="ticketID"
							required
							maxLength={50}
							control={control}
							values={validOptions["ticketID"]}
							exists={selectableFields["ticketID"].exists}
						/>
                        <IntegerInput
                            name="cost"
                            // required
                            register={register}
                        />
						<SelectInput
							name="carrier"
							required
							maxLength={50}
							control={control}
							values={validOptions["flightID"]}
							exists={selectableFields["flightID"].exists}
						/>
                        <SelectInput
							name="customer"
							required
							maxLength={50}
							control={control}
							values={validOptions["personID"]}
							exists={selectableFields["personID"].exists}
						/>
                        <SelectInput
							name="deplane_at"
							required
							maxLength={3}
							control={control}
							values={validOptions["airportID"]}
							exists={selectableFields["airportID"].exists}
						/>
                        <CharInput
                            name="seat_number"
                            maxLength={50}
                            required
                            register={register}
                        />
						<input type="submit" />
					</form>
				</>
			)}
		</div>
	);
}
