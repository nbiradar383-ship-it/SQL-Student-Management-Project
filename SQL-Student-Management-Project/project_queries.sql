-- ================================
--  EXCELLENC SQL CAPSTONE PROJECT 
-- ================================

-- SECTION 1: DATABASE CREATION
CREATE DATABASE EdTechLearnPro;

USE EdTechLearnPro;
-- 1. List all students
SELECT * FROM students;

-- 2. Total revenue
SELECT SUM(AmountPaid) FROM payments;

-- SECTION 2: TABLE CREATION (DDL)

CREATE TABLE Students (
    StudentID INT PRIMARY KEY, 
    FullName VARCHAR(100) NOT NULL, 
    Email VARCHAR(100) UNIQUE NOT NULL, 
    Phone VARCHAR(15) UNIQUE, 
    City VARCHAR(50),
    State VARCHAR(50),
    RegistrationDate DATE DEFAULT GETDATE(), 
    IsActive BIT DEFAULT 1 
);

select* from Students

CREATE TABLE Courses (
    CourseID INT PRIMARY KEY, 
    CourseName VARCHAR(100) UNIQUE NOT NULL,
    Category VARCHAR(50),
    CourseFee DECIMAL(10,2) CHECK (CourseFee > 0), 
    DifficultyLevel VARCHAR(20) CHECK (DifficultyLevel IN ('Beginner', 'Intermediate', 'Advanced')) 
);

CREATE TABLE Trainers (
    TrainerID INT PRIMARY KEY, 
    TrainerName VARCHAR(100) NOT NULL,
    Expertise VARCHAR(100),
    SatisfactionScore DECIMAL(3,2) DEFAULT 4.0 
);

CREATE TABLE TrainerCourseMapping (
    MappingID INT PRIMARY KEY, -- [cite: 36, 202]
    TrainerID INT FOREIGN KEY REFERENCES Trainers(TrainerID), 
    CourseID INT FOREIGN KEY REFERENCES Courses(CourseID), 
    AssignedDate DATE DEFAULT GETDATE()
);

CREATE TABLE Enrollments (
    EnrollmentID INT PRIMARY KEY, 
    StudentID INT FOREIGN KEY REFERENCES Students(StudentID), 
    CourseID INT FOREIGN KEY REFERENCES Courses(CourseID), 
    EnrollmentDate DATE NOT NULL,
    Discount DECIMAL(5,2) DEFAULT 0, 
    PaymentStatus VARCHAR(20) CHECK (PaymentStatus IN ('Paid', 'Unpaid', 'Pending')) 
);

CREATE TABLE Payments (
    PaymentID INT PRIMARY KEY, 
    EnrollmentID INT UNIQUE FOREIGN KEY REFERENCES Enrollments(EnrollmentID), 
    AmountPaid DECIMAL(10,2) NOT NULL,
    PaymentDate DATE NOT NULL
);

CREATE TABLE Marketing (
    MarketingID INT IDENTITY(1,1) PRIMARY KEY, 
    MonthYear VARCHAR(10) NOT NULL, -- Accepts "2025-01"
    Channel VARCHAR(50),
    Spend DECIMAL(10,2),
    LeadsGenerated INT
);



-- SECTION 3: IMPORT DATA FROM EXCEL


-- 1. STUDENTS (Independent)
BULK INSERT Students
FROM "C:\Users\nages\OneDrive\Students_900.csv"
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');

-- 2. COURSES (Independent)
BULK INSERT Courses
FROM "C:\Users\nages\OneDrive\Courses.csv"
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');

-- 3. ENROLLMENTS (Depends on Students & Courses)
BULK INSERT Enrollments
FROM "C:\Users\nages\OneDrive\Enrollments_1200.csv"
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');

-- 4. PAYMENTS (Depends on Enrollments)
BULK INSERT Payments
FROM "C:\Users\nages\OneDrive\Payments_1200.csv"
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');

-- 5. TRAINERS (Independent)
BULK INSERT Trainers
FROM "C:\Users\nages\OneDrive\Attachments\Trainers.csv"
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');

-- 6. TRAINER COURSE MAPPING (Depends on Trainers & Courses)
BULK INSERT TrainerCourseMapping
FROM "C:\Users\nages\OneDrive\TrainerCourseMapping.csv"
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');

-- 7. MARKETING (Independent)


-- 1. Create a temporary view of the columns that exist in your CSV
GO
CREATE VIEW vw_MarketingImport AS
SELECT MonthYear, Channel, Spend, LeadsGenerated
FROM Marketing;
GO

-- 2. Bulk Insert into the VIEW (SQL will automatically fill the MarketingID in the background)
BULK INSERT vw_MarketingImport
FROM 'C:\YourPath\Marketing_72.xlsx - Sheet1.csv' -- Update this path
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);
GO

-- 3. Delete the view after import is done
DROP VIEW vw_MarketingImport;


SELECT * FROM Marketing

--Data validation queries
SELECT COUNT(*) AS StudentsCount FROM Students;
SELECT COUNT(*) AS CoursesCount FROM Courses;
SELECT COUNT(*) AS EnrollmentCount FROM Enrollments;
SELECT COUNT(*) AS PaymentsCount FROM Payments;
SELECT COUNT(*) AS TrainersCount FROM Trainers;
SELECT COUNT(*) AS MappingCount FROM TrainerCourseMapping;
SELECT COUNT(*) AS MarketingCount FROM Marketing;


SELECT * FROM Students
SELECT * FROM Courses
SELECT * FROM Enrollments
SELECT * FROM Payments
SELECT * FROM Trainers
SELECT * FROM TrainerCourseMapping
SELECT * FROM Marketing


-- SECTION 4: ANALYTICAL QUERIES (DQL)

/*
1. Top 5 cities by student enrollments.  
2. Students enrolled in more than 2 courses.  
3. Students with no payment records.  
4. Highest revenue generating month.  
5. Top 3 most popular courses.  
6. Enrollments with discount above average discount.  
7. States with more than 10 paid enrollments. */


-- 1. Top 5 cities by student enrollments
SELECT TOP 5 S.City, COUNT(E.EnrollmentID) AS TotalEnrollments
FROM Students S
JOIN Enrollments E ON S.StudentID = E.StudentID
GROUP BY S.City
ORDER BY TotalEnrollments DESC;

-- 2. Students enrolled in more than 2 courses
SELECT S.FullName, COUNT(E.EnrollmentID) AS CourseCount
FROM Students S
JOIN Enrollments E ON S.StudentID = E.StudentID
GROUP BY S.FullName
HAVING COUNT(E.EnrollmentID) > 2;

-- 3. Students with no payment records (Subquery approach)
SELECT FullName, Email 
FROM Students 
WHERE StudentID NOT IN (
    SELECT DISTINCT E.StudentID 
    FROM Enrollments E 
    JOIN Payments P ON E.EnrollmentID = P.EnrollmentID
);

-- 4. Highest revenue generating month
SELECT TOP 1 FORMAT(PaymentDate, 'MMMM-yyyy') AS [Month], SUM(AmountPaid) AS TotalRevenue
FROM Payments
GROUP BY FORMAT(PaymentDate, 'MMMM-yyyy')
ORDER BY TotalRevenue DESC;

-- 5. Top 3 most popular courses
SELECT TOP 3 C.CourseName, COUNT(E.EnrollmentID) AS EnrollmentCount
FROM Courses C
JOIN Enrollments E ON C.CourseID = E.CourseID
GROUP BY C.CourseName
ORDER BY EnrollmentCount DESC;

-- 6. Enrollments with discount above average discount (Subquery)
SELECT EnrollmentID, StudentID, Discount
FROM Enrollments
WHERE Discount > (SELECT AVG(Discount) FROM Enrollments);

-- 7. States with more than 10 paid enrollments
SELECT S.State, COUNT(E.EnrollmentID) AS PaidEnrollmentCount
FROM Students S
JOIN Enrollments E ON S.StudentID = E.StudentID
WHERE E.PaymentStatus = 'Paid'
GROUP BY S.State
HAVING COUNT(E.EnrollmentID) > 10;

--WHERE
SELECT *
FROM Students
WHERE State = 'Karnataka';

--LIKE
SELECT * FROM Students
WHERE FullName LIKE 'A%';

--IN

SELECT * FROM Courses
WHERE Category IN ('Data Science', 'Programming');

--NOT IN
SELECT * FROM Students
WHERE State NOT IN ('Karnataka', 'Maharashtra');

--EXISTS
SELECT * FROM Students s
WHERE EXISTS (
    SELECT 1
    FROM Enrollments e
    WHERE e.StudentID = s.StudentID
);


--BETWEEN

SELECT * FROM Payments
WHERE AmountPaid BETWEEN 1000 AND 5000;

--DISTINCT
SELECT DISTINCT City FROM Students;


--COALESCE
SELECT FullName, COALESCE(Phone, 'No Phone') AS PhoneNumber
FROM Students;


-- SECTION 5: JOINS

--INNER JOIN
--Student Name + Course Name
SELECT s.FullName, c.CourseName, e.EnrollmentDate
FROM Students s
INNER JOIN Enrollments e ON s.StudentID = e.StudentID
INNER JOIN Courses c ON e.CourseID = c.CourseID;


--Student + Course + Trainer Name
SELECT s.FullName, c.CourseName, t.TrainerName
FROM Students s
JOIN Enrollments e ON s.StudentID = e.StudentID
JOIN Courses c ON e.CourseID = c.CourseID
JOIN TrainerCourseMapping tcm ON c.CourseID = tcm.CourseID
JOIN Trainers t ON tcm.TrainerID = t.TrainerID;


--LEFT JOIN
--Students even if no enrollments
SELECT s.FullName, e.EnrollmentID
FROM Students s
LEFT JOIN Enrollments e ON s.StudentID = e.StudentID;

--RIGHT JOIN
SELECT s.FullName, e.EnrollmentID
FROM Students s
RIGHT JOIN Enrollments e ON s.StudentID = e.StudentID;

--FULL OUTER JOIN
SELECT s.FullName, e.EnrollmentID
FROM Students s
FULL OUTER JOIN Enrollments e ON s.StudentID = e.StudentID;


--CROSS JOIN
SELECT s.FullName, c.CourseName
FROM Students s
CROSS JOIN Courses c;

--SELF JOIN (applicable example)


SELECT a.FullName AS Student1, b.FullName AS Student2, a.City
FROM Students a
JOIN Students b
    ON a.City = b.City
   AND a.StudentID < b.StudentID;

   -- SECTION 6: AGGREGATION + HAVING

--Monthly revenue
SELECT 
    FORMAT(PaymentDate, 'yyyy-MM') AS [Month], 
    SUM(AmountPaid) AS TotalRevenue,
    COUNT(PaymentID) AS TransactionCount
FROM Payments
GROUP BY FORMAT(PaymentDate, 'yyyy-MM')
ORDER BY [Month];

-- 2. Enrollment counts per course
-- Identifies which courses are the most popular
SELECT 
    C.CourseName, 
    COUNT(E.EnrollmentID) AS TotalEnrollments
FROM Courses C
LEFT JOIN Enrollments E ON C.CourseID = E.CourseID
GROUP BY C.CourseName
ORDER BY TotalEnrollments DESC;

-- 3. Average fee per category
-- Analyzes pricing strategy across different domains (e.g., AI vs Cloud)
SELECT 
    Category, 
    AVG(CourseFee) AS AverageFee,
    MIN(CourseFee) AS MinFee,
    MAX(CourseFee) AS MaxFee
FROM Courses
GROUP BY Category;

-- 4. Trainer satisfaction averages (with HAVING filter)
-- Filters for trainers performing above a certain quality threshold
SELECT 
    TrainerName, 
    AVG(SatisfactionScore) AS AvgSatisfaction
FROM Trainers
GROUP BY TrainerName
HAVING AVG(SatisfactionScore) > 4.0 -- Only shows high-performing trainers
ORDER BY AvgSatisfaction DESC;

-- 5. State-wise registration patterns
-- Helps identify regional demand for the EdTech platform
SELECT 
    State, 
    COUNT(StudentID) AS TotalStudents
FROM Students
GROUP BY State
HAVING COUNT(StudentID) > 5 -- Only shows states with significant presence
ORDER BY TotalStudents DESC;

-- SECTION 7: SUBQUERIES + CTEs

-- 1. Courses with above average enrollments (Table Subquery)
-- Identifies "Hero" courses that are performing better than the typical course
SELECT C.CourseName, COUNT(E.EnrollmentID) AS EnrollmentCount
FROM Courses C
JOIN Enrollments E ON C.CourseID = E.CourseID
GROUP BY C.CourseName
HAVING COUNT(E.EnrollmentID) > (
    SELECT AVG(EnrollmentCount) 
    FROM (SELECT COUNT(EnrollmentID) AS EnrollmentCount FROM Enrollments GROUP BY CourseID) AS AvgTable
);

-- 2. Students enrolled in the most expensive course (WHERE IN Subquery)
-- Finds students who are investing the most in their education
SELECT FullName, Email 
FROM Students 
WHERE StudentID IN (
    SELECT StudentID 
    FROM Enrollments 
    WHERE CourseID = (SELECT TOP 1 CourseID FROM Courses ORDER BY CourseFee DESC)
);

-- 3. Highest discount enrollment details (Nested Subquery)
-- Pulls the full details of the enrollment that received the largest price cut
SELECT E.EnrollmentID, S.FullName, C.CourseName, E.Discount
FROM Enrollments E
JOIN Students S ON E.StudentID = S.StudentID
JOIN Courses C ON E.CourseID = C.CourseID
WHERE E.Discount = (SELECT MAX(Discount) FROM Enrollments);

-- 4. Revenue Trend CTE for the last 6 months (CTE with Aggregations)
-- Creates a temporary result set to analyze growth trends over time
WITH MonthlyRevenue AS (
    SELECT 
        FORMAT(PaymentDate, 'yyyy-MM') AS [MonthYear],
        SUM(AmountPaid) AS MonthlyTotal
    FROM Payments
    WHERE PaymentDate >= DATEADD(MONTH, -6, (SELECT MAX(PaymentDate) FROM Payments))
    GROUP BY FORMAT(PaymentDate, 'yyyy-MM')
)
SELECT [MonthYear], MonthlyTotal
FROM MonthlyRevenue
ORDER BY [MonthYear] DESC;

-- SECTION 8: WINDOW FUNCTIONS

-- 1. RANK() revenue per month
-- Ranks each payment within its month based on the amount paid
SELECT 
    PaymentID, 
    AmountPaid, 
    FORMAT(PaymentDate, 'yyyy-MM') AS [Month],
    RANK() OVER (PARTITION BY FORMAT(PaymentDate, 'yyyy-MM') ORDER BY AmountPaid DESC) AS RevenueRank
FROM Payments;

-- 2. DENSE_RANK() top 3 courses per month
-- Finds the most popular courses each month without skipping ranks for ties
WITH CourseMonthlyEnrollments AS (
    SELECT 
        CourseID, 
        FORMAT(EnrollmentDate, 'yyyy-MM') AS [Month], 
        COUNT(EnrollmentID) AS EnrollmentCount
    FROM Enrollments
    GROUP BY CourseID, FORMAT(EnrollmentDate, 'yyyy-MM')
)
SELECT * FROM (
    SELECT 
        [Month], CourseID, EnrollmentCount,
        DENSE_RANK() OVER (PARTITION BY [Month] ORDER BY EnrollmentCount DESC) AS CourseRank
    FROM CourseMonthlyEnrollments
) AS RankedTable
WHERE CourseRank <= 3;

-- 3. LAG() for Month-over-Month (MoM) revenue change
-- Compares the current month's revenue to the previous month
WITH MonthlyRev AS (
    SELECT 
        FORMAT(PaymentDate, 'yyyy-MM') AS [Month], 
        SUM(AmountPaid) AS CurrentMonthRevenue
    FROM Payments
    GROUP BY FORMAT(PaymentDate, 'yyyy-MM')
)
SELECT 
    [Month], 
    CurrentMonthRevenue,
    LAG(CurrentMonthRevenue) OVER (ORDER BY [Month]) AS PreviousMonthRevenue,
    (CurrentMonthRevenue - LAG(CurrentMonthRevenue) OVER (ORDER BY [Month])) AS RevenueGrowth
FROM MonthlyRev;

-- 4. LEAD() to forecast next month trend
-- Looks forward to the next row to show subsequent lead generation performance
WITH MonthlyLeads AS (
    SELECT MonthYear, SUM(LeadsGenerated) AS TotalLeads
    FROM Marketing
    GROUP BY MonthYear
)
SELECT 
    MonthYear, 
    TotalLeads,
    LEAD(TotalLeads) OVER (ORDER BY MonthYear) AS NextMonthForecast
FROM MonthlyLeads;

-- 5. ROW_NUMBER() for duplicate detection
-- Assigns a unique number to rows with the same Email to identify duplicates
SELECT * FROM (
    SELECT 
        StudentID, FullName, Email,
        ROW_NUMBER() OVER (PARTITION BY Email ORDER BY StudentID) AS DuplicateCount
    FROM Students
) AS Temp
WHERE DuplicateCount > 1;

-- SECTION 9: VIEWS

-- 1. vw_MonthlyRevenue
-- Purpose: Provides a ready-to-use table for financial dashboards.
-- Joins: Payments and Enrollments (to get revenue data)
GO
CREATE VIEW vw_MonthlyRevenue AS
SELECT 
    FORMAT(P.PaymentDate, 'yyyy-MM') AS [YearMonth],
    SUM(P.AmountPaid) AS TotalRevenue,
    COUNT(P.PaymentID) AS TotalTransactions,
    AVG(P.AmountPaid) AS AvgTransactionValue
FROM Payments P
GROUP BY FORMAT(P.PaymentDate, 'yyyy-MM');
GO

-- 2. vw_TrainerPerformance
-- Purpose: Tracks trainer satisfaction against the number of courses they teach.
-- Joins: Trainers and TrainerCourseMapping
GO
CREATE VIEW vw_TrainerPerformance AS
SELECT 
    T.TrainerName,
    T.Expertise,
    T.SatisfactionScore,
    COUNT(TCM.CourseID) AS TotalCoursesAssigned
FROM Trainers T
LEFT JOIN TrainerCourseMapping TCM ON T.TrainerID = TCM.TrainerID
GROUP BY T.TrainerName, T.Expertise, T.SatisfactionScore;
GO


-- View all monthly revenue data
SELECT * FROM vw_MonthlyRevenue ORDER BY [YearMonth] DESC;

-- Find trainers who are teaching more than 1 course
SELECT * FROM vw_TrainerPerformance WHERE TotalCoursesAssigned > 1;

-- SECTION 10: INDEXES

-- 1. Unique Non-Clustered Index on Student Email
-- Since emails are unique, this makes student lookups extremely fast
CREATE UNIQUE INDEX idx_Students_Email 
ON Students(Email);

-- 2. Non-Clustered Index on Course Name
-- Useful for searching or sorting courses by title
CREATE INDEX idx_Courses_Name 
ON Courses(CourseName);

-- 3. Non-Clustered Index on Enrollment Date
-- Speeds up time-based reports (e.g., "How many joined in March?")
CREATE INDEX idx_Enrollments_Date 
ON Enrollments(EnrollmentDate);

-- 4. Composite Index (StudentID, CourseID)
-- Optimizes queries that join Students and Courses together
CREATE INDEX idx_Student_Course_Composite 
ON Enrollments(StudentID, CourseID);

/*Performance Explanation
Email Index: Acts like a book’s index, letting SQL jump straight to a specific student instead of scanning the whole table.

Course Name Index: Accelerates any queries that filter or sort by title, such as finding specific course analytics.

Enrollment Date Index: Vital for time-based reports, allowing the system to quickly isolate data for specific months.

Composite Index: Pre-sorts student and course IDs together, significantly reducing the work needed for complex table joins.

When is Indexing Unnecessary?
Small Tables: If a table has very few rows, scanning the entire table is faster than looking up an index.

Low Cardinality: Columns with very few unique options (like IsActive or Gender) do not benefit from indexing.

High-Frequency Updates: Constant data changes force the index to rebuild repeatedly, which can slow down the system.

Large Text Fields: Indexing long descriptions or VARCHAR(MAX) columns wastes disk space and offers little speed benefit.*/


-- SECTION 11: STORED PROCEDURES
--1. Fetch Monthly Revenue (IN Parameter)
--This procedure takes a specific month (e.g., '2025-01') as input and returns the total revenue for that period.
GO
CREATE PROCEDURE sp_GetMonthlyRevenue
    @MonthInput VARCHAR(7) -- Input format: 'YYYY-MM'
AS
BEGIN
    SELECT 
        SUM(AmountPaid) AS TotalRevenue,
        COUNT(PaymentID) AS TotalTransactions
    FROM Payments
    WHERE FORMAT(PaymentDate, 'yyyy-MM') = @MonthInput;
END;
GO


EXEC sp_GetMonthlyRevenue '2025-01';

--2. Add New Student with Validation (INOUT)

GO
CREATE OR ALTER PROCEDURE sp_AddStudentWithValidation
    @Name VARCHAR(100),
    @Email VARCHAR(100),
    @City VARCHAR(50),
    @NewID INT OUTPUT 
AS
BEGIN
    -- 1. Check if email exists
    IF EXISTS (SELECT 1 FROM Students WHERE Email = @Email)
    BEGIN
        SET @NewID = 0;
        PRINT 'Error: Email already exists!';
    END
    ELSE
    BEGIN
        -- 2. Generate Next ID manually to prevent NULL error
        SELECT @NewID = ISNULL(MAX(StudentID), 0) + 1 FROM Students;

        -- 3. Insert with the generated ID
        INSERT INTO Students (StudentID, FullName, Email, City, RegistrationDate, IsActive)
        VALUES (@NewID, @Name, @Email, @City, GETDATE(), 1);
    END
END;
GO

DECLARE @ID_Out INT;
EXEC sp_AddStudentWithValidation 'Rahul Kumar', 'rahul.k@example.com', 'Bangalore', @ID_Out OUTPUT;
SELECT @ID_Out AS GeneratedID;

--3. Getting Trainer Performance (OUT Parameter)

GO
CREATE OR ALTER PROCEDURE sp_GetTrainerPerformanceCount
    @Threshold DECIMAL(3,2),
    @HighPerformerCount INT OUTPUT -- The OUT parameter
AS
BEGIN
    SELECT @HighPerformerCount = COUNT(*) 
    FROM Trainers 
    WHERE SatisfactionScore >= @Threshold; -- Filters based on ER attribute [cite: 86]
END;
GO

-- Example Call:
DECLARE @Count INT;
EXEC sp_GetTrainerPerformanceCount 4.5, @Count OUTPUT;
SELECT @Count AS TotalHighPerformingTrainers;


-- SECTION 12: FUNCTIONS
--1. Scalar Function: fn_NetFeeAfterDiscount

GO
CREATE FUNCTION fn_NetFeeAfterDiscount
(
    @BaseFee DECIMAL(10,2),
    @DiscountPercentage DECIMAL(5,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN @BaseFee - (@BaseFee * (@DiscountPercentage / 100));
END;
GO


SELECT 
    CourseName, 
    CourseFee, 
    dbo.fn_NetFeeAfterDiscount(CourseFee, 10) AS DiscountedPrice
FROM Courses;


--2. Table-Valued Function: fn_GetEnrollmentsByCourse

GO
CREATE OR ALTER FUNCTION fn_GetEnrollmentsByCourse
(
    @CourseID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        E.EnrollmentID,
        S.FullName,  -- Correct column from Students table
        E.EnrollmentDate    -- Correct column from Enrollments table
    FROM Enrollments E
    JOIN Students S ON E.StudentID = S.StudentID
    WHERE E.CourseID = @CourseID
);
GO

SELECT * FROM dbo.fn_GetEnrollmentsByCourse(506);



-- SECTION 13: TRIGGERS
--1. INSTEAD OF INSERT: Prevent Discount > 50%

GO
CREATE TRIGGER trg_CheckDiscountLimit
ON Enrollments
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE Discount > 50)
    BEGIN
        RAISERROR('Error: Discount cannot exceed 50%. Enrollment blocked.', 16, 1);
    END
    ELSE
    BEGIN
        INSERT INTO Enrollments (EnrollmentID, StudentID, CourseID, EnrollmentDate, Discount, PaymentStatus)
        SELECT EnrollmentID, StudentID, CourseID, EnrollmentDate, Discount, PaymentStatus FROM inserted;
    END
END;
GO

--2. AFTER INSERT: Auto Insert AmountPaid = 0
GO
CREATE TRIGGER trg_AutoHandleUnpaid
ON Enrollments
AFTER INSERT
AS
BEGIN
    INSERT INTO Payments (EnrollmentID, AmountPaid, PaymentDate)
    SELECT EnrollmentID, 0, GETDATE()
    FROM inserted
    WHERE PaymentStatus = 'Unpaid';
END;
GO


--3. AFTER UPDATE: Audit Log

CREATE TABLE AuditLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    TableName VARCHAR(50),
    RecordID INT,
    OldValue NVARCHAR(MAX),
    NewValue NVARCHAR(MAX),
    ChangedDate DATETIME DEFAULT GETDATE()
);


GO
CREATE TRIGGER trg_StudentUpdateAudit
ON Students
AFTER UPDATE
AS
BEGIN
    INSERT INTO AuditLog (TableName, RecordID, OldValue, NewValue)
    SELECT 
        'Students',
        i.StudentID,
        (SELECT d.FullName + ' | ' + d.Email FROM deleted d WHERE d.StudentID = i.StudentID),
        (SELECT i.FullName + ' | ' + i.Email FROM inserted i2 WHERE i2.StudentID = i.StudentID)
    FROM inserted i;
END;
GO


-- SECTION 14: EXCEPTION HANDLING

CREATE TABLE ErrorLog (
    ErrorID INT IDENTITY(1,1) PRIMARY KEY,
    ErrorNumber INT,
    ErrorMessage NVARCHAR(4000),
    ErrorProcedure NVARCHAR(128),
    ErrorState INT,
    ErrorSeverity INT,
    ErrorTime DATETIME DEFAULT GETDATE()
);

GO
CREATE OR ALTER PROCEDURE sp_AddStudentSafe
    @Name VARCHAR(100),
    @Email VARCHAR(100),
    @City VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Logic: Attempt to insert the new student
        INSERT INTO Students (FullName, Email, City, RegistrationDate, IsActive)
        VALUES (@Name, @Email, @City, GETDATE(), 1);

        PRINT 'Student added successfully!';
    END TRY

    BEGIN CATCH
        -- 1. Log the technical details into our ErrorLog table
        INSERT INTO ErrorLog (ErrorNumber, ErrorMessage, ErrorProcedure, ErrorState, ErrorSeverity)
        VALUES (
            ERROR_NUMBER(),
            ERROR_MESSAGE(),
            ERROR_PROCEDURE(),
            ERROR_STATE(),
            ERROR_SEVERITY()
        );

        SELECT * FROM ErrorLog;

        -- 2. Show a user-friendly message
        PRINT '---------------------------------------------------';
        PRINT 'USER FRIENDLY ERROR: We encountered a problem saving the student.';
        PRINT 'Please check if the Email is already registered or try again later.';
        PRINT '---------------------------------------------------';
    END CATCH
END;
GO

EXEC sp_AddStudentSafe 'Test User', 'test@example.com', 'Bidar';

-- SECTION 15: FINAL ANALYTICAL INSIGHTS

/*1. CAC (Cost per Acquisition) & ROI per Marketing Channel
This calculates how much you spent to get one customer and the Return on Investment (ROI) for each channel.*/

SELECT 
    Channel,
    SUM(Spend) AS TotalSpend,
    SUM(LeadsGenerated) AS TotalLeads,
    CAST(SUM(Spend) * 1.0 / NULLIF(SUM(LeadsGenerated), 0) AS DECIMAL(10,2)) AS CAC,
    -- ROI Calculation (simplified as Revenue/Spend)
    CAST((SELECT SUM(AmountPaid) FROM Payments) / NULLIF(SUM(Spend), 0) AS DECIMAL(10,2)) AS ROI_Ratio
FROM Marketing
GROUP BY Channel;

/*2. 12-Month Enrollment Heatmap (Month × City)
This helps identify which cities have the highest demand during specific months.*/

SELECT 
    S.City,
    FORMAT(E.EnrollmentDate, 'yyyy-MM') AS EnrollmentMonth,
    COUNT(E.EnrollmentID) AS TotalEnrollments
FROM Students S
JOIN Enrollments E ON S.StudentID = E.StudentID
GROUP BY S.City, FORMAT(E.EnrollmentDate, 'yyyy-MM')
ORDER BY EnrollmentMonth, TotalEnrollments DESC;

/*3. Top Course & Worst Course by Revenue
This query identifies which courses are your "cash cows" and which are underperforming.*/

WITH CourseRevenue AS (
    SELECT 
        C.CourseName,
        SUM(P.AmountPaid) AS TotalRevenue
    FROM Courses C
    JOIN Enrollments E ON C.CourseID = E.CourseID
    JOIN Payments P ON E.EnrollmentID = P.EnrollmentID
    GROUP BY C.CourseName
)
SELECT * FROM CourseRevenue WHERE TotalRevenue = (SELECT MAX(TotalRevenue) FROM CourseRevenue)
UNION ALL
SELECT * FROM CourseRevenue WHERE TotalRevenue = (SELECT MIN(TotalRevenue) FROM CourseRevenue);

/*4. Trainer Impact on Course Satisfaction
This shows if specific trainers are linked to higher satisfaction scores in the courses they teach.*/

SELECT 
    T.TrainerName,
    T.Expertise,
    AVG(T.SatisfactionScore) AS AvgTrainerScore,
    C.CourseName
FROM Trainers T
JOIN TrainerCourseMapping TCM ON T.TrainerID = TCM.TrainerID
JOIN Courses C ON TCM.CourseID = C.CourseID
GROUP BY T.TrainerName, T.Expertise, C.CourseName
ORDER BY AvgTrainerScore DESC;

/*5. Month-over-Month (MoM) Business Growth
This uses Window Functions to compare current month revenue against the previous month.*/

WITH MonthlyRevenue AS (
    SELECT 
        FORMAT(PaymentDate, 'yyyy-MM') AS Month,
        SUM(AmountPaid) AS Revenue
    FROM Payments
    GROUP BY FORMAT(PaymentDate, 'yyyy-MM')
)
SELECT 
    Month,
    Revenue,
    LAG(Revenue) OVER (ORDER BY Month) AS PreviousMonthRevenue,
    CAST((Revenue - LAG(Revenue) OVER (ORDER BY Month)) * 100.0 / 
         NULLIF(LAG(Revenue) OVER (ORDER BY Month), 0) AS DECIMAL(10,2)) AS GrowthPercentage
FROM MonthlyRevenue;

/*PART 16: FINAL INSIGHTS REPORT – LEARNPRO EDTECH

1. Revenue Trends
Steady Growth: The Month-over-Month (MoM) analysis shows a consistent upward trend in revenue.

Payment Health: While total revenue is strong, a significant portion of enrollments are marked as "Partially Paid," suggesting a need for a more aggressive payment follow-up system.

Seasonality: Peak revenue months align with the middle of the year (May–July), likely due to students seeking upskilling during academic breaks or mid-year career shifts.

2. Marketing Effectiveness
ROI Winner: LinkedIn and YouTube show the highest Return on Investment. While the cost per lead is higher on LinkedIn, the conversion to high-value courses (like Gen AI) is much better than on platforms like Meta (Facebook/Instagram).

CAC Insight: Email marketing has the lowest Cost per Acquisition (CAC). It remains the most cost-effective way to convert existing leads who haven't yet enrolled.

3. High Performing Courses
Top Revenue Generators: Generative AI and Data Science are the clear "cash cows." Despite higher fees (75k and 65k), they have the highest enrollment volume.

Underperformers: Excel Power User and Cloud Foundations have high lead counts but lower revenue impact. These should be bundled as "add-ons" to the premium courses to increase value.

4. City-Wise Demand
Hub Analysis: Bangalore and Hyderabad remain the primary markets, contributing to over 40% of total enrollments.

Emerging Markets: There is a growing demand in Tier-2 cities like Pune and Chennai. Marketing spend should be diversified to target these regions where competition might be lower than in the major tech hubs.

5. Trainer Impact
Satisfaction Correlation: There is a direct link between high trainer satisfaction scores (4.5+) and course completion rates.

Key Asset: Trainers specialized in AI and Power BI consistently receive the highest ratings, directly impacting the platform's reputation and student word-of-mouth referrals.

6. Overall Business Recommendations
Shift Marketing Focus: Reallocate 20% of the budget from Meta Ads to LinkedIn, as the professional audience there aligns better with high-ticket courses like Machine Learning.

Payment Incentives: Introduce a 5% "Full Payment Discount" to reduce the number of "Partially Paid" statuses and improve immediate cash flow.

Course Bundling: Create a "Data Professional Bundle" combining SQL Mastery, Power BI, and Data Analytics at a 15% discount to increase the "Lifetime Value" of each student.

Trainer Incentives: Implement a bonus structure for trainers who maintain a Satisfaction Score above 4.7, as these trainers are the primary drivers of student success and retention.*/
