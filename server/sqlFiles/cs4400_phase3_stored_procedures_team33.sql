set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;
set @thisDatabase = 'flight_management';

use flight_management;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [1] add_airplane()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airplane.  A new airplane must be sponsored
by an existing airline, and must have a unique tail number for that airline.
username.  An airplane must also have a non-zero seat capacity and speed. An airplane
might also have other factors depending on it's type, like skids or some number
of engines.  Finally, an airplane must have a database-wide unique location if
it will be used to carry passengers. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS add_airplane;
DELIMITER //

CREATE PROCEDURE add_airplane (
    IN ip_airlineID VARCHAR(50),
    IN ip_tail_num VARCHAR(50),
    IN ip_seat_capacity INTEGER,
    IN ip_speed INTEGER,
    IN ip_locationID VARCHAR(50),
    IN ip_plane_type VARCHAR(100),
    IN ip_skids BOOLEAN,
    IN ip_propellers INTEGER,
    IN ip_jet_engines INTEGER
)
sp_main: BEGIN
    -- unique airline
    IF NOT EXISTS(SELECT 1 FROM airline WHERE airlineID = ip_airlineID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Airline does not exist.';
        LEAVE sp_main;
    END IF;

    -- tail number unique for airline
    IF EXISTS(SELECT 1 FROM airplane WHERE airlineID = ip_airlineID AND tail_num = ip_tail_num) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tail number already exists for airline.';
        LEAVE sp_main;
    END IF;

    -- seat capacity and speed are nonzero
    IF ip_seat_capacity <= 0 OR ip_speed <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Seat capacity and speed must be greater than zero.';
        LEAVE sp_main;
    END IF;

    -- plane type restrictions
    IF ip_plane_type = 'prop' THEN
        IF ip_skids IS NULL OR ip_propellers IS NULL OR ip_jet_engines IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid plane type information provided.';
            LEAVE sp_main;
        END IF;
    ELSEIF ip_plane_type = 'jet' THEN
        IF ip_skids IS NOT NULL OR ip_propellers IS NOT NULL OR ip_jet_engines IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid plane type information provided.';
            LEAVE sp_main;
        END IF;
    ELSEIF ip_plane_type IS NULL THEN
        IF ip_skids IS NOT NULL OR ip_propellers IS NOT NULL OR ip_jet_engines IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid plane type information provided.';
            LEAVE sp_main;
        END IF;
    END IF;

    -- location
    IF ip_locationID IS NOT NULL AND ip_locationID IN (SELECT locationID FROM airplane) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Location exists for another airplane.';
        LEAVE sp_main;
    END IF;

    -- Insert new location record
    IF ip_locationID IS NOT NULL THEN
        INSERT INTO location (locationID) VALUES (ip_locationID);
    END IF;

    -- Insert new airplane record
    INSERT INTO airplane (airlineID, tail_num, seat_capacity, speed, locationID, plane_type, skids, propellers, jet_engines)
    VALUES (ip_airlineID, ip_tail_num, ip_seat_capacity, ip_speed, ip_locationID, ip_plane_type, ip_skids, ip_propellers, ip_jet_engines);
END //
DELIMITER ;

-- [2] add_airport()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airport.  A new airport must have a unique
identifier along with a database-wide unique location if it will be used to support
airplane takeoffs and landings.  An airport may have a longer, more descriptive
name.  An airport must also have a city and state designation. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS add_airport;
DELIMITER //

CREATE PROCEDURE add_airport (
    IN ip_airportID CHAR(3),
    IN ip_airport_name VARCHAR(200),
    IN ip_city VARCHAR(100),
    IN ip_state CHAR(2),
    IN ip_locationID VARCHAR(50)
)
sp_main: BEGIN
    -- unique airport
    IF EXISTS(SELECT 1 FROM airport WHERE airportID = ip_airportID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Airport ID already exists.';
        LEAVE sp_main;
    END IF;

    -- unique location if provided
    IF ip_locationID IS NOT NULL AND EXISTS(SELECT 1 FROM location WHERE locationID = ip_locationID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Location ID already exists.';
        LEAVE sp_main;
    END IF;

    -- has a city and state designation
    IF ip_city IS NULL OR ip_state IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'City and state must be specified.';
        LEAVE sp_main;
    END IF;

    -- location
    IF ip_locationID IS NOT NULL AND ip_locationID IN (SELECT locationID FROM airport) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Location exists for another airplane.';
        LEAVE sp_main;
    END IF;

    -- Insert new location record
    IF ip_locationID IS NOT NULL THEN
        INSERT INTO location (locationID) VALUES (ip_locationID);
    END IF;

    INSERT INTO airport (airportID, airport_name, city, state, locationID)
    VALUES (ip_airportID, ip_airport_name, ip_city, ip_state, ip_locationID);
END //
DELIMITER ;

-- [3] add_person()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new person.  A new person must reference a unique
identifier along with a database-wide unique location used to determine where the
person is currently located: either at an airport, or on an airplane, at any given
time.  A person may have a first and last name as well.

Also, a person can hold a pilot role, a passenger role, or both roles.  As a pilot,
a person must have a tax identifier to receive pay, and an experience level.  Also,
a pilot might be assigned to a specific airplane as part of the flight crew.  As a
passenger, a person will have some amount of frequent flyer miles. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS add_person;
DELIMITER //

CREATE PROCEDURE add_person (
    IN ip_personID VARCHAR(50),
    IN ip_first_name VARCHAR(100),
    IN ip_last_name VARCHAR(100),
    IN ip_locationID VARCHAR(50),
    IN ip_taxID VARCHAR(50),
    IN ip_experience INTEGER,
    IN ip_flying_airline VARCHAR(50),
    IN ip_flying_tail VARCHAR(50),
    IN ip_miles INTEGER
)
sp_main: BEGIN
    -- unique personID
    IF EXISTS(SELECT 1 FROM person WHERE personID = ip_personID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Person ID already exists.';
        LEAVE sp_main;
    END IF;

    -- Must have a unique location that exists
    IF ip_locationID IS NULL OR NOT EXISTS(SELECT 1 FROM location WHERE locationID = ip_locationID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid location ID provided.';
        LEAVE sp_main;
    END IF;

    -- Must have a first name
    IF ip_first_name IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'First name must be specified.';
        LEAVE sp_main;
    END IF;

    -- check if they are either a pilot or passenger
    IF ip_miles IS NULL AND ip_taxID IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Must specify either tax ID or miles.';
        LEAVE sp_main;
    END IF;

    -- Create person
    INSERT INTO person (personID, first_name, last_name, locationID)
    VALUES (ip_personID, ip_first_name, ip_last_name, ip_locationID);

    -- If a person is a pilot they must have an experience level and valid airline and flying tail data
    IF ip_taxID IS NOT NULL AND ip_experience IS NOT NULL 
        AND ((ip_flying_airline IS NULL AND ip_flying_tail IS NULL) 
            OR (ip_flying_airline IS NOT NULL AND ip_flying_tail IS NOT NULL
                AND EXISTS (SELECT 1 FROM airplane 
                    WHERE airlineID = ip_flying_airline AND tail_num = ip_flying_tail)))
    THEN 
        INSERT INTO pilot (personID, taxID, experience, flying_airline, flying_tail)
        VALUES (ip_personID, ip_taxID, ip_experience, ip_flying_airline, ip_flying_tail);
    END IF;

    -- Create passenger
    IF ip_miles IS NOT NULL THEN
        INSERT INTO passenger (personID, miles)
        VALUES (ip_personID, ip_miles);
    END IF;
END //

DELIMITER ;


-- [4] grant_pilot_license()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new pilot license.  The license must reference
a valid pilot, and must be a new/unique type of license for that pilot. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS grant_pilot_license;
DELIMITER //

CREATE PROCEDURE grant_pilot_license (
    IN ip_personID VARCHAR(50),
    IN ip_license VARCHAR(100)
)
sp_main: BEGIN
    -- pilot exists
    IF NOT EXISTS (SELECT 1 FROM pilot WHERE personID = ip_personID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pilot does not exist.';
        LEAVE sp_main;
    END IF;

    -- unique license
    IF EXISTS (SELECT 1 FROM pilot_licenses WHERE personID = ip_personID AND license = ip_license) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'License already exists for this pilot.';
        LEAVE sp_main;
    END IF;

    -- Insert new pilot license record
    INSERT INTO pilot_licenses (personID, license)
    VALUES (ip_personID, ip_license);
END //

DELIMITER ;


-- [5] offer_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new flight.  The flight can be defined before
an airplane has been assigned for support, but it must have a valid route.  Once
an airplane has been assigned, we must also track where the airplane is along
the route, whether it is in flight or on the ground, and when the next action -
takeoff or landing - will occur. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS offer_flight;
DELIMITER //

CREATE PROCEDURE offer_flight (
    IN ip_flightID VARCHAR(50),
    IN ip_routeID VARCHAR(50),
    IN ip_support_airline VARCHAR(50),
    IN ip_support_tail VARCHAR(50),
    IN ip_progress INTEGER,
    IN ip_airplane_status VARCHAR(100),
    IN ip_next_time TIME
)
sp_main: BEGIN
    -- Route exists
    IF NOT EXISTS (SELECT 1 FROM route WHERE routeID = ip_routeID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid route ID provided.';
        LEAVE sp_main;
    END IF;

    -- Must be a unique flightID
    IF EXISTS (SELECT 1 FROM flight WHERE flightID = ip_flightID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Flight ID already exists.';
        LEAVE sp_main;
    END IF;

    -- If they have an airline but no tail or vice versa
    IF (ip_support_airline IS NULL AND ip_support_tail IS NOT NULL) 
        OR (ip_support_airline IS NOT NULL AND ip_support_tail IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid support data provided.';
        LEAVE sp_main;
    END IF;

    -- If there is not an assigned airplane but there is a progress, status, or next_time
    IF ip_support_airline IS NULL AND ip_support_tail IS NULL 
        AND (ip_progress IS NOT NULL OR ip_airplane_status IS NOT NULL OR ip_next_time IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid data provided for an unassigned airplane.';
        LEAVE sp_main;
    END IF;

    -- If there is an assigned airplane but no progress, status, or next_time
    IF ip_support_airline IS NOT NULL AND ip_support_tail IS NOT NULL 
        AND (ip_progress IS NULL OR ip_airplane_status IS NULL OR ip_next_time IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid data provided for an assigned airplane.';
        LEAVE sp_main;
    END IF;

    -- Insert new flight record
    INSERT INTO flight (flightID, routeID, support_airline, support_tail, progress, airplane_status, next_time)
    VALUES (ip_flightID, ip_routeID, ip_support_airline, ip_support_tail, ip_progress, ip_airplane_status, ip_next_time);
END //

DELIMITER ;

-- [6] purchase_ticket_and_seat()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new ticket.  The cost of the flight is optional
since it might have been a gift, purchased with frequent flyer miles, etc.  Each
flight must be tied to a valid person for a valid flight.  Also, we will make the
(hopefully simplifying) assumption that the departure airport for the ticket will
be the airport at which the traveler is currently located.  The ticket must also
explicitly list the destination airport, which can be an airport before the final
airport on the route.  Finally, the seat must be unoccupied. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS purchase_ticket_and_seat;
DELIMITER //

CREATE PROCEDURE purchase_ticket_and_seat (
    IN ip_ticketID VARCHAR(50),
    IN ip_cost INTEGER,
    IN ip_carrier VARCHAR(50),
    IN ip_customer VARCHAR(50),
    IN ip_deplane_at CHAR(3),
    IN ip_seat_number VARCHAR(50)
)
sp_main: BEGIN
    -- person exists
    IF NOT EXISTS (SELECT 1 FROM person WHERE personID = ip_customer) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid customer ID provided.';
        LEAVE sp_main;
    END IF;

    -- flight exists
    IF NOT EXISTS (SELECT 1 FROM flight WHERE flightID = ip_carrier) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid flight ID provided.';
        LEAVE sp_main;
    END IF;

    -- ticket doesn't exist
    IF EXISTS (SELECT 1 FROM ticket WHERE ticketID = ip_ticketID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket ID already exists.';
        LEAVE sp_main;
    END IF;

	-- check seat is unoccupied
	IF EXISTS (SELECT 1 FROM ticket NATURAL JOIN ticket_seats
		WHERE ticket.carrier = ip_carrier AND ticket_seats.seat_number = ip_seat_number) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The seat is already occupied.';
        LEAVE sp_main;
    END IF;

    -- destination airport must exist
    IF ip_deplane_at IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid destination airport provided.';
        LEAVE sp_main;
    END IF;

    -- gets the last arrival airport sequence # in a flight path that matches with
    -- this carrier and deplaning airport. 
    -- MAY NEED TO CHECK IT OCCURS AFTER THE DEPARTURE AIRPORT.
    IF NOT EXISTS (
        SELECT rp.sequence FROM (route_path AS rp 
        JOIN leg AS l ON rp.legID = l.legID) 
        JOIN flight AS f ON f.routeID = rp.routeID 
        WHERE l.arrival = ip_deplane_at AND f.flightID = ip_carrier
        ORDER BY rp.sequence DESC LIMIT 1
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid destination airport for this flight.';
        LEAVE sp_main;
    END IF;

    -- insert the ticket and seat information
    INSERT INTO ticket (ticketID, cost, carrier, customer, deplane_at)
    VALUES (ip_ticketID, ip_cost, ip_carrier, ip_customer, ip_deplane_at);

    INSERT INTO ticket_seats (ticketID, seat_number)
    VALUES (ip_ticketID, ip_seat_number);
END //

DELIMITER ;

-- [7] add_update_leg()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new leg as specified.  However, if a leg from
the departure airport to the arrival airport already exists, then don't create a
new leg - instead, update the existence of the current leg while keeping the existing
identifier.  Also, all legs must be symmetric.  If a leg in the opposite direction
exists, then update the distance to ensure that it is equivalent.   */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS add_update_leg;
DELIMITER //

CREATE PROCEDURE add_update_leg (
    IN ip_legID VARCHAR(50),
    IN ip_distance INTEGER,
    IN ip_departure CHAR(3),
    IN ip_arrival CHAR(3)
)
sp_main:
BEGIN
    -- Check that airports exist
    IF NOT EXISTS(SELECT 1 FROM airport WHERE airportID = ip_departure) 
        OR NOT EXISTS(SELECT 1 FROM airport WHERE airportID = ip_arrival) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'One or both airports do not exist';
        LEAVE sp_main;
    END IF;

    -- Temporarily stores existing and opposite leg if they exist
    SET @existing_leg := (SELECT legID FROM leg WHERE departure = ip_departure AND arrival = ip_arrival);
    SET @opposite_leg := (SELECT legID FROM leg WHERE departure = ip_arrival AND arrival = ip_departure);

    IF @existing_leg IS NULL THEN
        INSERT INTO leg (legID, distance, departure, arrival) VALUES (ip_legID, ip_distance, ip_departure, ip_arrival);
    ELSE
        UPDATE leg SET distance = ip_distance WHERE legID = @existing_leg;
    END IF;
    
    IF @opposite_leg IS NOT NULL AND ip_distance != (SELECT distance FROM leg WHERE legID = @opposite_leg) THEN
        UPDATE leg SET distance = ip_distance WHERE legID = @opposite_leg;
    END IF;
END //

DELIMITER ;


-- [8] start_route()
-- -----------------------------------------------------------------------------
/* This stored procedure creates the first leg of a new route.  Routes in our
system must be created in the sequential order of the legs.  The first leg of
the route can be any valid leg. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS start_route;

DELIMITER //

CREATE PROCEDURE start_route (
    IN ip_routeID VARCHAR(50),
    IN ip_legID VARCHAR(50)
)
sp_main: BEGIN
    -- make sure leg exists
    IF NOT EXISTS (SELECT 1 FROM leg where legID = ip_legID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The specified leg does not exist.';
        LEAVE sp_main;
    END IF;
    
    -- create route if it doesn't already exist
    IF NOT EXISTS (SELECT 1 FROM route WHERE routeID = ip_routeID) THEN
		INSERT INTO route (routeID) VALUES (ip_routeID);
		INSERT INTO route_path (routeID, legID, sequence) VALUES (ip_routeID, ip_legID, 1);
    END IF;
END //
DELIMITER ;


-- [9] extend_route()
-- -----------------------------------------------------------------------------
/* This stored procedure adds another leg to the end of an existing route.  Routes
in our system must be created in the sequential order of the legs, and the route
must be contiguous: the departure airport of this leg must be the same as the
arrival airport of the previous leg. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS extend_route;
DELIMITER //
CREATE PROCEDURE extend_route (in ip_routeID varchar(50), in ip_legID varchar(50))
sp_main: BEGIN
    -- make sure leg exists
    IF NOT EXISTS (SELECT 1 FROM leg where legID = ip_legID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Leg does not exist';
        LEAVE sp_main;
    END IF;

    -- make sure route exists
    IF NOT EXISTS (SELECT 1 FROM route WHERE routeID = ip_routeID) AND 
        NOT EXISTS (SELECT 1 FROM route_path WHERE routeID = ip_routeID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Route does not exist';
        LEAVE sp_main;
    END IF;
    
    -- set lastLeg equal to the last leg for a given route based on sequence values
    SELECT arrival, sequence INTO @lastArrival, @lastSequence FROM leg NATURAL JOIN route_path
        WHERE routeID = ip_routeID ORDER BY sequence DESC LIMIT 1;
    
    -- make sure the lastLeg's arrival airport is the same as the new leg's departure
    IF @lastArrival != (SELECT departure FROM leg where legID = ip_legID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Last leg arrival airport is not the same as the new leg departure airport';
        LEAVE sp_main;
    END IF;
    
    INSERT INTO route_path (routeID, legID, sequence) VALUES (ip_routeID, ip_legID, @lastSequence + 1);
END //
DELIMITER ;

-- [10] flight_landing()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight landing at the next airport
along it's route.  The time for the flight should be moved one hour into the future
to allow for the flight to be checked, refueled, restocked, etc. for the next leg
of travel.  Also, the pilots of the flight should receive increased experience, and
the passengers should have their frequent flyer miles updated. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS flight_landing;
DELIMITER //

CREATE PROCEDURE flight_landing (in ip_flightID varchar(50))
sp_main: BEGIN
	-- Check if the flight exists and is flying with a support airline and tail
    IF NOT EXISTS (SELECT 1 FROM flight WHERE flightID = ip_flightID AND airplane_status = 'in_flight' 
		AND support_airline IS NOT NULL AND support_tail IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Flight does not exist or is not flying with a support airline and tail';
        LEAVE sp_main;
	END IF;
    
    -- Set status to on_ground
    UPDATE flight SET airplane_status = 'on_ground' WHERE flightID = ip_flightID;
    
    -- Shift time by one hour
	UPDATE flight SET next_time = ADDTIME(next_time, '01:00:00') WHERE flightID = ip_flightID;

	-- Increase experience
	UPDATE pilot SET experience = experience + 1 WHERE (flying_airline, flying_tail) 
		IN (SELECT support_airline, support_tail FROM flight WHERE flightID = ip_flightID);

	-- Get distance from the last leg that was traversed
    SELECT routeID, progress INTO @routeID, @progress FROM flight WHERE flightID = ip_flightID;
    SELECT distance INTO @legDistance FROM route_path NATURAL JOIN leg 
		WHERE routeID = @routeID AND sequence = @progress;
	
	-- Increase frequent flyer miles based on the leg distance
	UPDATE passenger SET miles = miles + @legDistance WHERE personID IN (SELECT customer FROM ticket WHERE carrier = ip_flightID);
END //

DELIMITER ;

-- [11] flight_takeoff()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight taking off from its current
airport towards the next airport along it's route.  The time for the next leg of
the flight must be calculated based on the distance and the speed of the airplane.
And we must also ensure that propeller driven planes have at least one pilot
assigned, while jets must have a minimum of two pilots. If the flight cannot take
off because of a pilot shortage, then the flight must be delayed for 30 minutes. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS flight_takeoff;
DELIMITER //
CREATE PROCEDURE flight_takeoff (in ip_flightID varchar(50))
sp_main: BEGIN
	-- flight exists and is flying with a support airline and tail
    IF NOT EXISTS (SELECT 1 FROM flight WHERE flightID = ip_flightID AND airplane_status = 'on_ground' 
		AND support_airline IS NOT NULL AND support_tail IS NOT NULL) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Flight is not on ground or has no support airline/tail';
		LEAVE sp_main;
    END IF;
    
    -- get info for matching airplane to flight
    (SELECT support_airline, support_tail INTO @support_airline, @support_tail FROM flight WHERE flightID = ip_flightID);
    (SELECT plane_type, locationID, speed INTO @plane_type, @locationID, @speed FROM airplane 
		WHERE airlineID = @support_airline AND tail_num = @support_tail);
    
    -- get pilots on this flight
    SET @pilotCount = (SELECT COUNT(*) FROM pilot WHERE flying_airline = @support_airline AND flying_tail = @support_tail);
    
    -- check if there are enough pilots for a given plane type
    IF (@plane_type != 'jet' AND @pilotCount < 1) 
		OR (@plane_type = 'jet' AND @pilotCount < 2) THEN
		UPDATE flight SET next_time = ADDTIME(next_time, '00:30:00') WHERE flightID = ip_flightID;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient pilots for the given plane type';
		LEAVE sp_main;
	END IF;

	-- Get distance from the next leg traversed
    (SELECT routeID, progress INTO @routeID, @progress FROM flight WHERE flightID = ip_flightID);
    
    -- Make sure there exists a leg associated with the route at all
    IF NOT EXISTS(SELECT 1 FROM route_path WHERE routeID = @routeID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No route path found for the given route ID';
		LEAVE sp_main;
	END IF;
    
    (SELECT distance, departure, arrival INTO @distance, @departure, @arrival 
		FROM route_path NATURAL JOIN leg WHERE routeID = @routeID AND sequence = @progress + 1);
    SET @flightTime = SEC_TO_TIME(3600 * (@distance / @speed));
    
    -- Shift time by flight time
	UPDATE flight SET next_time = IFNULL(ADDTIME(next_time, @flightTime), @flightTime) WHERE flightID = ip_flightID;
    
	-- Set status to in_flight
    UPDATE flight SET airplane_status = 'in_flight' WHERE flightID = ip_flightID;
    
    -- Update progress
    UPDATE flight SET progress = progress + 1 WHERE flightID = ip_flightID;
END //
DELIMITER ;

-- [12] passengers_board()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting on a flight at
its current airport.  The passengers must be at the airport and hold a valid ticket
for the flight. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS passengers_board;
DELIMITER //
CREATE PROCEDURE passengers_board (in ip_flightID varchar(50))
sp_main: BEGIN
	-- Flight exists and is on ground
	IF NOT EXISTS (SELECT 1 FROM flight WHERE flightID = ip_flightID AND airplane_status = 'on_ground' 
		AND support_airline IS NOT NULL AND support_tail IS NOT NULL) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Flight does not exist or is not on ground.';
		LEAVE sp_main;
	END IF;

	-- Get last leg traversed
	(SELECT routeID, progress, support_airline, support_tail INTO @routeID, @progress, @support_airline, @support_tail FROM flight WHERE flightID = ip_flightID);
	(SELECT distance, departure, arrival INTO @lastDistance, @lastDeparture, @lastArrival 
		FROM route_path NATURAL JOIN leg WHERE routeID = @routeID AND sequence = IF(@progress != 0, @progress, 1));
	SET @airportLocation := (SELECT locationID FROM airport WHERE airportID = IF(@progress != 0, @lastArrival, @lastDeparture));
	SET @airplaneLocation := (SELECT locationID FROM airplane WHERE airlineID = @support_airline AND tail_num = @support_tail);

	-- Get all passengers at the airport with valid tickets and update their locations
    UPDATE person NATURAL JOIN passenger 
		SET locationID = @airplaneLocation
		WHERE locationID = @airportLocation AND personID IN 
        (SELECT customer FROM ticket WHERE carrier = ip_flightID);
END //
DELIMITER ;


-- [13] passengers_disembark()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting off of a flight
at its current airport. The passengers must be on that flight, and the flight must
be located at the destination airport as referenced by the ticket. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS passengers_disembark;
DELIMITER //
CREATE PROCEDURE passengers_disembark (IN ip_flightID VARCHAR(50))
SP_MAIN: BEGIN
	-- Flight exists and is on ground
    IF NOT EXISTS (SELECT 1 FROM flight WHERE flightID = ip_flightID AND airplane_status = 'on_ground' 
        AND support_airline IS NOT NULL AND support_tail IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Flight is not on ground with a support airline and tail.';
		LEAVE sp_main;
   END IF;
    
    -- Get last leg traversed
    (SELECT routeID, progress, support_airline, support_tail INTO @routeID, @progress, @support_airline, @support_tail FROM flight WHERE flightID = ip_flightID);
	(SELECT distance, departure, arrival INTO @lastDistance, @lastDeparture, @lastArrival 
		FROM route_path NATURAL JOIN leg WHERE routeID = @routeID AND sequence = @progress);
	SET @airportLocation := (SELECT locationID FROM airport WHERE airportID = @lastArrival);
    SET @airplaneLocation := (SELECT locationID FROM airplane WHERE airlineID = @support_airline AND tail_num = @support_tail);
    
    -- Get all passengers on the plane with valid tickets and update their locations
    UPDATE person NATURAL JOIN passenger 
		SET locationID = @airportLocation
		WHERE locationID = @airplaneLocation
			AND personID NOT IN (SELECT personID FROM pilot 
				WHERE flying_airline = @support_airline AND flying_tail = @support_tail)
			AND personID IN (SELECT customer FROM ticket 
				WHERE carrier = ip_flightID AND deplane_at = @lastArrival);
END //
DELIMITER ;

-- [14] assign_pilot()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a pilot as part of the flight crew for a given
airplane.  The pilot being assigned must have a license for that type of airplane,
and must be at the same location as the flight.  Also, a pilot can only support
one flight (i.e. one airplane) at a time.  The pilot must be assigned to the flight
and have their location updated for the appropriate airplane. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS assign_pilot;
DELIMITER //
CREATE PROCEDURE assign_pilot (IN ip_flightID VARCHAR(50), IN ip_personID VARCHAR(50))
sp_main: BEGIN
    -- pilot exists
    IF NOT EXISTS (SELECT 1 FROM pilot WHERE personID = ip_personID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid pilot';
        LEAVE sp_main;
    END IF;
    
    -- pilot isn't flying another airplane currently
    IF (SELECT flying_airline FROM pilot WHERE personID = ip_personID) IS NOT NULL 
        OR (SELECT flying_tail FROM pilot WHERE personID = ip_personID) IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pilot is flying another airplane';
        LEAVE sp_main;
    END IF;
    
    -- flight exists and is on the ground with a support airline and tail
    IF NOT EXISTS (SELECT 1 FROM flight WHERE flightID = ip_flightID AND airplane_status = 'on_ground' 
        AND support_airline IS NOT NULL AND support_tail IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid flight';
        LEAVE sp_main;
    END IF;
    
    -- get info for matching airplane to flight
    (SELECT support_airline, support_tail INTO @support_airline, @support_tail FROM flight WHERE flightID = ip_flightID);
    (SELECT plane_type, locationID, airlineID, tail_num INTO @plane_type, @locationID, @airlineID, @tail_num FROM airplane 
        WHERE airlineID = @support_airline AND tail_num = @support_tail);
    (SELECT routeID, progress INTO @routeID, @progress FROM flight WHERE flightID = ip_flightID);
    (SELECT distance, departure, arrival INTO @lastDistance, @lastDeparture, @lastArrival 
        FROM route_path NATURAL JOIN leg WHERE routeID = @routeID AND sequence = IF(@progress != 0, @progress, 1));
    SET @airportLocation := (SELECT locationID FROM airport WHERE airportID = IF(@progress != 0, @lastArrival, @lastDeparture));
    
    -- check if pilot has required licenses and is at the airplane location
    IF @plane_type NOT IN (SELECT license FROM pilot NATURAL JOIN pilot_licenses WHERE personID = ip_personID) 
        OR @airportLocation != (SELECT locationID FROM person WHERE personID = ip_personID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pilot does not have required licenses or is not at the airplane location';
        LEAVE sp_main;
    END IF;
    
    -- update location, airline, and tail of the pilot
    UPDATE person NATURAL JOIN pilot
        SET locationID = @locationID, 
            flying_airline = @airlineID,
            flying_tail = @tail_num
        WHERE personID = ip_personID;
END //
DELIMITER ;

-- [15] recycle_crew()
-- -----------------------------------------------------------------------------
/* This stored procedure releases the assignments for a given flight crew.  The
flight must have ended, and all passengers must have disembarked. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS recycle_crew;
DELIMITER //
CREATE PROCEDURE recycle_crew (IN ip_flightID VARCHAR(50))
sp_main:
BEGIN
    -- Flight exists and is on ground
    IF NOT EXISTS (SELECT 1 FROM flight WHERE flightID = ip_flightID AND airplane_status = 'on_ground' 
        AND support_airline IS NOT NULL AND support_tail IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Flight does not exist or is not on the ground';
		LEAVE sp_main;
    END IF;
    
    (SELECT routeID, progress INTO @routeID, @progress FROM flight WHERE flightID = ip_flightID);
	
    -- flight has ended
    IF @progress != (SELECT MAX(sequence) FROM route_path WHERE routeID = @routeID) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Flight is still in progress';
        LEAVE sp_main;
	END IF;
    
    -- get info for matching airplane to flight
    (SELECT support_airline, support_tail INTO @support_airline, @support_tail FROM flight WHERE flightID = ip_flightID);
    (SELECT locationID INTO @airplaneLocation FROM airplane WHERE airlineID = @support_airline AND tail_num = @support_tail);
	(SELECT distance, departure, arrival INTO @lastDistance, @lastDeparture, @lastArrival 
		FROM route_path NATURAL JOIN leg WHERE routeID = @routeID AND sequence = @progress);
	SET @airportLocation := (SELECT locationID FROM airport WHERE airportID = @lastArrival);    
    
    -- check if all passengers (who are not pilots) have disembarked
    IF EXISTS (SELECT 1 FROM person NATURAL JOIN passenger WHERE personID NOT IN (SELECT personID FROM pilot 
		WHERE flying_airline = @support_airline AND flying_tail = @support_tail)
		AND locationID = @airplaneLocation) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'All passengers have not yet disembarked';
		LEAVE sp_main;
    END IF;
        
    UPDATE person NATURAL JOIN pilot 
		SET flying_airline = NULL, flying_tail = NULL, locationID = @airportLocation
		WHERE flying_airline = @support_airline AND flying_tail = @support_tail;
END //
DELIMITER ;

-- [16] retire_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a flight that has ended from the system.  The
flight must be on the ground, and either be at the start its route, or at the
end of its route.  */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS retire_flight;
DELIMITER //
CREATE PROCEDURE retire_flight (IN ip_flightID VARCHAR(50))
sp_main: BEGIN
	-- Flight exists and is on ground. Can either be assigned a plane or not be assigned one yet.
    IF NOT EXISTS (SELECT 1 FROM flight WHERE flightID = ip_flightID AND airplane_status = 'on_ground' 
        AND ((support_airline IS NOT NULL AND support_tail IS NOT NULL) 
			OR (support_airline IS NULL AND support_tail IS NULL))) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid flight ID or airplane status';
        LEAVE sp_main;
    END IF;
    
	(SELECT routeID, progress INTO @routeID, @progress FROM flight WHERE flightID = ip_flightID);
	
    -- flight has ended or hasn't started
    IF @progress NOT IN (0, (SELECT MAX(sequence) FROM route_path WHERE routeID = @routeID)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot retire flight that has already started';
		LEAVE sp_main;
    END IF;
    
    -- get info for matching airplane to flight
    (SELECT support_airline, support_tail INTO @support_airline, @support_tail FROM flight WHERE flightID = ip_flightID);
    (SELECT locationID INTO @airplaneLocation FROM airplane WHERE airlineID = @support_airline AND tail_num = @support_tail);
    
    DELETE FROM flight WHERE flightID = ip_flightID;    
END //
DELIMITER ;

-- [17] remove_passenger_role()
-- -----------------------------------------------------------------------------
/* This stored procedure removes the passenger role from person.  The passenger
must be on the ground at the time; and, if they are on a flight, then they must
disembark the flight at the current airport.  If the person had both a pilot role
and a passenger role, then the person and pilot role data should not be affected.
If the person only had a passenger role, then all associated person data must be
removed as well. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS remove_passenger_role;

DELIMITER //

CREATE PROCEDURE remove_passenger_role (in ip_personID varchar(50))
sp_main:
BEGIN
    IF NOT EXISTS (SELECT 1 FROM passenger WHERE personID = ip_personID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Person is not a passenger';
        LEAVE sp_main;
    END IF;

    IF NOT EXISTS (SELECT locationID FROM person NATURAL JOIN passenger 
        WHERE personID = ip_personID AND locationID LIKE 'plane%') THEN
        IF NOT EXISTS (SELECT 1 FROM pilot WHERE personID = ip_personID) THEN
            DELETE FROM passenger WHERE personID = ip_personID;
            DELETE FROM person WHERE personID = ip_personID;
        ELSE
            DELETE FROM passenger WHERE personID = ip_personID;
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Passenger is still onboard a flight';
        LEAVE sp_main;
    END IF;
END //

DELIMITER ;

-- [18] remove_pilot_role()
-- -----------------------------------------------------------------------------
/* This stored procedure removes the pilot role from person.  The pilot must not
be assigned to a flight; or, if they are assigned to a flight, then that flight
must either be at the start or end of its route.  If the person had both a pilot
role and a passenger role, then the person and passenger role data should not be
affected.  If the person only had a pilot role, then all associated person data
must be removed as well. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS remove_pilot_role;
DELIMITER //
CREATE PROCEDURE remove_pilot_role (IN ip_personID VARCHAR(50))
SP_MAIN: BEGIN
    IF NOT EXISTS (SELECT 1 FROM pilot WHERE personID = ip_personID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Person is not a pilot';
        LEAVE sp_main;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM passenger WHERE personID = ip_personID) THEN
        DELETE FROM pilot_licenses WHERE personID = ip_personID;
        DELETE FROM pilot WHERE personID = ip_personID;
        DELETE FROM person WHERE personID = ip_personID;
    ELSE
        DELETE FROM pilot_licenses WHERE personID = ip_personID;
        DELETE FROM pilot WHERE personID = ip_personID;
    END IF;
END //
DELIMITER ;

-- [19] flights_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where flights that are currently airborne are located. */
-- -----------------------------------------------------------------------------
create or replace view flights_in_the_air (departing_from, arriving_at, num_flights,
	flight_list, earliest_arrival, latest_arrival, airplane_list) as
SELECT dep.airportID AS departing_from,
       arr.airportID AS arriving_at, 
       COUNT(*) AS num_flights,
       GROUP_CONCAT(DISTINCT f.flightID) AS flight_list, 
       MIN(f.next_time) AS earliest_arrival,
       MAX(f.next_time) AS latest_arrival,
       GROUP_CONCAT(DISTINCT a.locationID) AS airplane_list
FROM flight AS f NATURAL JOIN route_path AS rp NATURAL JOIN leg AS l
JOIN airport AS dep ON l.departure = dep.airportID
JOIN airport AS arr ON l.arrival = arr.airportID
JOIN airplane a ON f.support_airline = a.airlineID AND f.support_tail = a.tail_num
WHERE f.airplane_status = 'in_flight' AND f.progress = rp.sequence
GROUP BY l.legID;

-- [20] flights_on_the_ground()
-- -----------------------------------------------------------------------------
/* This view describes where flights that are currently on the ground are located. */
-- -----------------------------------------------------------------------------
create or replace view flights_on_the_ground (departing_from, num_flights,
	flight_list, earliest_arrival, latest_arrival, airplane_list) as 
SELECT dep.airportID AS departing_from,
       COUNT(*) AS num_flights,
       GROUP_CONCAT(DISTINCT f.flightID) AS flight_list, 
       MIN(f.next_time) AS earliest_arrival,
       MAX(f.next_time) AS latest_arrival,
       GROUP_CONCAT(DISTINCT a.locationID) AS airplane_list
FROM airport AS dep JOIN leg ON (dep.airportID = leg.arrival OR dep.airportID = leg.departure)
NATURAL JOIN route_path AS rp NATURAL JOIN flight AS f
JOIN airplane a ON f.support_airline = a.airlineID AND f.support_tail = a.tail_num
WHERE f.airplane_status = 'on_ground' AND 
((dep.airportID = leg.arrival AND f.progress = rp.sequence) 
OR (dep.airportID = leg.departure AND f.progress = 0 AND rp.sequence = 1))
GROUP BY dep.airportID ORDER BY dep.airportID;

-- [21] people_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently airborne are located. */
-- -----------------------------------------------------------------------------
create or replace view people_in_the_air (departing_from, arriving_at, num_airplanes,
	airplane_list, flight_list, earliest_arrival, latest_arrival, num_pilots,
	num_passengers, joint_pilots_passengers, person_list) as
SELECT 
  dep.airportID AS departing_from,
  arr.airportID AS arriving_at, 
  COUNT(DISTINCT a.locationID) AS num_airplanes,
  GROUP_CONCAT(DISTINCT a.locationID ORDER BY a.locationID) AS airplane_list,
  GROUP_CONCAT(DISTINCT f.flightID ORDER BY f.flightID) AS flight_list,
  MIN(f.next_time) AS earliest_arrival,
  MAX(f.next_time) AS latest_arrival,
  COUNT(DISTINCT pt.personID) AS num_pilots,
  COUNT(DISTINCT p.personID) AS num_passengers,
  COUNT(DISTINCT pp.personID) AS joint_pilots_passengers,
  GROUP_CONCAT(DISTINCT pp.personID ORDER BY pp.personID ASC SEPARATOR ',') AS person_list
FROM flight AS f NATURAL JOIN route_path AS rp NATURAL JOIN leg AS l
JOIN airport AS dep ON l.departure = dep.airportID
JOIN airport AS arr ON l.arrival = arr.airportID
JOIN airplane AS a ON f.support_airline = a.airlineID AND f.support_tail = a.tail_num
JOIN (passenger NATURAL JOIN person AS p) ON p.locationID = a.locationID
LEFT JOIN (pilot NATURAL JOIN person AS pt) ON pt.locationID = a.locationID
JOIN (SELECT personID FROM person UNION SELECT personID FROM pilot) AS pp 
	ON pp.personID = p.personID OR pp.personID = pt.personID
WHERE f.progress = rp.sequence AND f.airplane_status = 'in_flight'
GROUP BY l.legID ORDER BY dep.airportID, arr.airportID;

-- [22] people_on_the_ground()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently on the ground are located. */
-- -----------------------------------------------------------------------------
create or replace view people_on_the_ground (departing_from, airport, airport_name,
	city, state, num_pilots, num_passengers, joint_pilots_passengers, person_list) as
SELECT 
  dep.airportID AS departing_from,
  dep.locationID as airport,
  dep.airport_name as airport_name,
  dep.city as city,
  dep.state as state,
  COUNT(DISTINCT pt.personID) AS num_pilots,
  COUNT(DISTINCT p.personID) AS num_passengers,
  COUNT(DISTINCT pp.personID) AS joint_pilots_passengers,
  GROUP_CONCAT(DISTINCT pp.personID ORDER BY pp.personID ASC SEPARATOR ',') AS person_list
FROM airport AS dep NATURAL JOIN (passenger NATURAL JOIN person AS p) 
LEFT JOIN (SELECT * FROM person WHERE personID IN (SELECT personID FROM pilot)) AS pt ON pt.locationID = dep.locationID
JOIN (SELECT personID FROM person UNION SELECT personID FROM pilot) AS pp 
	ON pp.personID = p.personID OR pp.personID = pt.personID
GROUP BY dep.airportID ORDER BY dep.airportID;

-- [23] route_summary()
-- -----------------------------------------------------------------------------
/* This view describes how the routes are being utilized by different flights. */
-- -----------------------------------------------------------------------------
create or replace view route_summary (route, num_legs, leg_sequence, route_length,
	num_flights, flight_list, airport_sequence) as
SELECT 
    rp.routeID AS route,
    COUNT(DISTINCT l.legID) AS num_legs,
    GROUP_CONCAT(DISTINCT l.legID ORDER BY rp.sequence) AS leg_sequence,
    total_distance as route_length,
    COUNT(DISTINCT f.flightID) as num_flights,
    GROUP_CONCAT(DISTINCT f.flightID )as flight_list,
    GROUP_CONCAT(DISTINCT CONCAT(l.departure, '->', l.arrival) ORDER BY rp.sequence) AS airport_sequence
FROM (route_path AS rp NATURAL JOIN leg AS l) LEFT JOIN flight AS f ON f.routeID = rp.routeID
JOIN (SELECT rp.routeID, SUM(distance) AS total_distance
        FROM leg NATURAL JOIN route_path AS rp GROUP BY rp.routeID) AS ld ON rp.routeID = ld.routeID
GROUP BY rp.routeID;

-- [24] alternative_airports()
-- -----------------------------------------------------------------------------
/* This view displays airports that share the same city and state. */
-- -----------------------------------------------------------------------------
create or replace view alternative_airports (city, state, num_airports,
	airport_code_list, airport_name_list) as
SELECT 
  city, 
  state, 
  COUNT(DISTINCT airportID) AS num_airports, 
  GROUP_CONCAT(DISTINCT airportID) AS airport_code_list, 
  GROUP_CONCAT(DISTINCT airport_name ORDER BY airportID) AS airport_name_list
FROM airport
GROUP BY city, state
HAVING COUNT(DISTINCT airportID) > 1;

-- [25] simulation_cycle()
-- -----------------------------------------------------------------------------
/* This stored procedure executes the next step in the simulation cycle.  The flight
with the smallest next time in chronological order must be identified and selected.
If multiple flights have the same time, then flights that are landing should be
preferred over flights that are taking off.  Similarly, flights with the lowest
identifier in alphabetical order should also be preferred.

If an airplane is in flight and waiting to land, then the flight should be allowed
to land, passengers allowed to disembark, and the time advanced by one hour until
the next takeoff to allow for preparations.

If an airplane is on the ground and waiting to takeoff, then the passengers should
be allowed to board, and the time should be advanced to represent when the airplane
will land at its next location based on the leg distance and airplane speed.

If an airplane is on the ground and has reached the end of its route, then the
flight crew should be recycled to allow rest, and the flight itself should be
retired from the system. */
-- -----------------------------------------------------------------------------
drop procedure if exists simulation_cycle;
DELIMITER //
create procedure simulation_cycle()
sp_main: begin
	-- get next flight
	SET @minFlightTime := (SELECT MIN(next_time) FROM flight);
    -- if there are no flights left to simulate
    IF @minFlightTime IS NULL THEN
		LEAVE sp_main;
    END IF;
	(SELECT f.flightID, f.airplane_status, f.progress, f.routeID INTO @nextFlight, @airplaneStatus, @progress, @routeID
		FROM flight AS f WHERE f.next_time = @minFlightTime ORDER BY airplane_status, flightID ASC LIMIT 1);
	    
    -- in flight
    IF @airplaneStatus = 'in_flight' THEN
		CALL flight_landing(@nextFlight);
        CALL passengers_disembark(@nextFlight);
	-- flight hasn't ended
	ELSEIF @progress != (SELECT MAX(sequence) FROM route_path WHERE routeID = @routeID) THEN
		CALL passengers_board(@nextFlight);
        CALL flight_takeoff(@nextFlight);
    ELSE -- flight is on the ground
		CALL recycle_crew(@nextFlight);
        CALL retire_flight(@nextFlight);
    END IF;
end //
DELIMITER ;
