# How to run

Install NodeJS, NPM, React, and MySQL

## Front End

1. `cd frontend`
2. `npm install`
3. `npm run dev`

## Backend

1. `cd server`
2. `npm install`
3. `npm run dev`

## MySQL

1. Open MySQL and create a local instance.
2. If your MySQL password is not 'password', either update the password in `functions.js` to your password or run the following command: <br>
   `ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';`<br>
   `flush privileges;`
3. SQL scripts will be automatically ran when backend server is started.

# Description

We created a NextJS and React based frontend along with an Express based backend. Our backend leveraged connections to our MySQL database completed in Phase 3 and edited further in Phase 4. We used request parameters and data within our backend post and get requests to modularize any requests sent to the backend for interacting with our database. For our frontend, we used modular NextJS routing for both the views and tables, along with a list of all pages that needed to be created, to create and populate table and view pages with information from the database. For our procedures, we created individual pages for each procedure due to the large variability in logic, but used custom-created react components to help modularize the process.

# Work Distribution

Although all of us worked together to design the structure of our project—the technologies we would be using, the methodology behind how we were going to retrieve data, how we would handle errors, etc—we divided work further to help build out the whole project.

-   Dylan created all of the React components, html, and css for the form inputs, forms, and pages for all tables, views, and procedures.
-   Connor designed and architected the interactions between our frontend and our backend, helping build the methods used to modularly handle get and post requests, along with receiving data and errors on the frontend.
-   Adil programmed all of the specific logic for each procedure on the frontend, completing all of the procedure pages.
-   Faiq fixed any issues within our Phase 3 SQL procedures and scripts, added proper error handling on leave conditions, and updating the file for use within Phase 4.
