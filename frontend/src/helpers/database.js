const handleFetchPromise = async (fetchPromise) => {
	return fetchPromise
		.then((response) => response.json())
		.then((result) => {
			if (result.error) {
				const message = JSON.stringify(
					result.error.sqlMessage ?? result.error,
					null,
					2
				);
				console.error(`error! ${message}`);
				throw new Error(message);
			} else {
				console.log("success!");
				return result;
			}
		})
		.catch((error) => {
			throw error;
		});
};

export const queryDB = async (query) => {
	const promise = fetch(`http://localhost:3001/get/${query}`);
	return await handleFetchPromise(promise);
};

export const modifyDB = async (procedure, data) => {
	const promise = fetch(`http://localhost:3001/${procedure}`, {
		method: "POST",
		headers: { "Content-Type": "application/json" },
		body: JSON.stringify(data),
	});

	return await handleFetchPromise(promise);
};

export const runSQLFile = async (type) => {
	const promise = fetch(`http://localhost:3001/${type}`);
	await handleFetchPromise(promise)
		.then((res) => alert(res))
		.catch((e) => alert(e.toString()));
};

export const queryValidOptions = async (selectableFields) => {
	const promises = Object.entries(selectableFields).map(
		async ([key, value]) => [key, await queryDB(value.query)]
	);

	return await Promise.all(promises).then((results) => {
		const reducedResults = {};
		for (const [key, value] of results) {
			reducedResults[key] = value.map((item) => item[key]);
		}

		return reducedResults;
	});
};
