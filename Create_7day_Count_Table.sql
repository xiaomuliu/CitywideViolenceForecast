DROP TABLE X_7DAY_COUNT;
CREATE TABLE X_7DAY_COUNT
(
    YEAR VARCHAR2(4),
    MONTH VARCHAR2(2),
    DAY VARCHAR2(2),
    RETRIEVAL_TIME DATE,
    ACTUAL_COUNT INT,
    PRIMARY KEY (YEAR, MONTH, DAY)
);
commit;