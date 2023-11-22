import { Controller } from "react-hook-form";
import CreatableSelect from "react-select/creatable";

export const CharInput = ({
	name,
	required = false,
	maxLength = 50,
	register,
}) => {
	const rules = {
		required: { value: required, message: "This field is required" },
		validate: {
			maxLength: (value) =>
				((value === null || !value) && !required) ||
				value.length <= maxLength ||
				`Max length is ${maxLength}`,
		},
	};

	return <input type="text" placeholder={name} {...register(name, rules)} />;
};

export const IntegerInput = ({
	name,
	required = false,
	min = null,
	max = null,
	register,
}) => {
	const needsValue = (value) => (value === null || isNaN(value)) && !required;

	const rules = {
		required: { value: required, message: "This field is required" },
		valueAsNumber: { value: required, message: "Input must be a number" },
		validate: {
			isInt: (value) =>
				needsValue(value) ||
				(!isNaN(value) && Number.isInteger(value)) ||
				"Input must be an integer",
		},
	};

	if (min)
		rules.validate.meetsMin = (value) =>
			needsValue(value) || value >= min || `Min value is ${min}`;

	if (max)
		rules.validate.meetsMax = (value) =>
			needsValue(value) || value <= max || `Max value is ${max}`;

	return (
		<input type="number" placeholder={name} {...register(name, rules)} />
	);
};

export const SelectInput = ({
	name,
	required,
	control,
	values,
	exists,
	...rest
}) => {
	const rules = {
		required: {
			value: required,
			message: "This field is required",
		},
		validate: {
			validateSelectedOption: (value) =>
				((value === null || !value) && !required) ||
				(exists == null || !(exists ^ values.includes(value))) ||
				"Invalid option selected",
		},
	};

	if (rest?.maxLength)
		rules.validate.maxLength = (value) =>
			((value === null || !value) && !required) ||
			value.length <= rest.maxLength ||
			`Max length is ${rest.maxLength}`;

	return (
		<Controller
			name={name}
			control={control}
			render={({ field: { onChange, value, name, ref } }) => (
				<CreatableSelect
					inputRef={ref}
					value={values.find((option) => option.value === value)}
					name={name}
					isClearable
					onChange={(value) => onChange(value?.value)}
					placeholder={name}
					options={values.map((value) => ({ value, label: value }))}
				/>
			)}
			rules={rules}
		/>
	);
};
