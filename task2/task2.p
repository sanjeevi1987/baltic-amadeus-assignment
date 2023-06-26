
/*------------------------------------------------------------------------
    File        : task2.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Subhash Sanjeevi
    Created     : Mon Jun 26 13:42:54 EEST 2023
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */
DEFINE VARIABLE lcFileName AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcDate     AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcISODate  AS CHARACTER NO-UNDO.

DEFINE STREAM strout.

DEFINE BUFFER b_Employee FOR Employee.
DEFINE BUFFER b_Family   FOR Family.

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */

ASSIGN lcDate = STRING(YEAR(TODAY), "9999") + 
                STRING(MONTH(TODAY), "99")  + 
                STRING(DAY(TODAY), "99")        
       lcFileName = "EmployeesReport" + "_" + lcDate + "_" + STRING(TIME) + ".csv".
             
OUTPUT STREAM strout TO VALUE("task2/report/" + lcFileName).

PUT STREAM strout UNFORMATTED
    QUOTER("EmpNum")     ";" 
    QUOTER("Type")       ";" 
    QUOTER("First Name") ";" 
    QUOTER("Last Name")  ";" 
    QUOTER("Birth Date") SKIP.
    
FOR EACH b_Employee NO-LOCK WHERE
         b_Employee.EmpNum <= 40 BY b_Employee.BirthDate:
             
    IF NOT CAN-FIND(FIRST b_Family NO-LOCK WHERE
                          b_Family.EmpNum EQ b_Employee.EmpNum) THEN NEXT.
    
    PUT STREAM strout UNFORMATTED
        QUOTER(b_Employee.EmpNum)                                 ";"
        QUOTER("Employee")                                        ";"
        QUOTER(b_Employee.FirstName)                              ";"
        QUOTER(b_Employee.LastName)                               ";"
        QUOTER(STRING(YEAR(b_Employee.BirthDate), "9999") + "-" + 
               STRING(MONTH(b_Employee.BirthDate), "99")  + "-" +
               STRING(DAY(b_Employee.BirthDate), "99"))           SKIP.
        
    FOR EACH b_Family NO-LOCK WHERE
             b_Family.EmpNum EQ b_Employee.EmpNum BY b_Family.BirthDate DESC:
                 
        PUT STREAM strout UNFORMATTED
            QUOTER("")                                              ";"
            QUOTER(b_Family.Relation)                               ";"
            QUOTER(ENTRY(1,b_Family.RelativeName," "))              ";"
            QUOTER(ENTRY(2,b_Family.RelativeName," "))              ";"
            QUOTER(STRING(YEAR(b_Family.Birthdate), "9999") + "-" + 
                   STRING(MONTH(b_Family.Birthdate), "99")  + "-" +
                   STRING(DAY(b_Family.Birthdate), "99"))           SKIP.
                                  
    END.      
END.

OUTPUT STREAM strout CLOSE.