export const handleSubmissionErrors = (errors) =>
	alert(
		`Please correct the errors in the form and try again. There are errors within the following fields:\n${Object.entries(
			errors
		)
			.map(([key, value]) => `${key}: ${value.message}`)
			.join(",\n")}`
	);
