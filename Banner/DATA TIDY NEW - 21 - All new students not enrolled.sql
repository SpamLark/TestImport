/*
*
* New students to be data tidied
* Updated 24-FEB-2022 - SRC
*
*/

--CREATE TABLE obu_datatidying_new AS
SELECT
	spriden_id AS "Student_Number",
    spriden_last_name || ', ' || spriden_first_name AS "Student_Name",
    CASE WHEN sprhold_hldd_code = 'RX' THEN 'Y' END AS "Current_RX_Hold",
    b1.sgbstdn_stst_code AS "Current_Student_Status",
    a1.sorlcur_camp_code AS "Campus",
    a1.sorlcur_program AS "Programme_Code",
    smrprle_program_desc AS "Programme_Description",
    a1.sorlcur_levl_code AS "Level",
    to_char(a1.sorlcur_start_date,'DD-MON-YYYY') AS "Expected_Start_Date",
    to_char(a1.sorlcur_end_date, 'DD-MON-YYYY') AS "Expected_Completion_Date",
	skricas_cas_number AS "CAS_Number",
    skricas_cas_status AS "CAS_Status",
    szrenrl_academic_enrol_status AS "Academic_Enrolment_Status", 
    szrenrl_financial_enrol_status AS "Financial_Enrolment_Status",
    szrenrl_overall_enrol_status AS "Overall_Enrolment_Status",
    a1.sorlcur_pidm,
    a1.sorlcur_program,
    a1.sorlcur_start_date,
    a1.SORLCUR_KEY_SEQNO,
    a1.SORLCUR_TERM_CODE_ADMIT
FROM 
	sorlcur a1
	JOIN spriden ON a1.sorlcur_pidm = spriden_pidm AND spriden_change_ind IS NULL
    JOIN sgbstdn b1 ON a1.sorlcur_pidm = b1.sgbstdn_pidm
    JOIN smrprle ON a1.sorlcur_program = smrprle_program
    LEFT JOIN sprhold ON a1.sorlcur_pidm = sprhold_pidm AND sprhold_hldd_code = 'RX' AND sysdate BETWEEN sprhold_from_date AND sprhold_to_date
    LEFT JOIN skricas ON a1.sorlcur_pidm = skricas_pidm AND a1.sorlcur_seqno = skricas_lcur_seqno
    LEFT JOIN szrenrl ON a1.sorlcur_pidm = szrenrl_pidm AND szrenrl_term_code = :current_term
WHERE
	1=1
	
	-- SORLCUR requirements  
	AND a1.sorlcur_lmod_code = 'LEARNER'
	AND a1.sorlcur_cact_code = 'ACTIVE'
	AND a1.sorlcur_current_cde = 'Y'
	AND a1.sorlcur_term_code = ( 
		
		SELECT MAX(a2.sorlcur_term_code)
		FROM sorlcur a2
		WHERE
			1=1
			AND a1.sorlcur_pidm = a2.sorlcur_pidm
			AND a1.sorlcur_key_seqno = a2.sorlcur_key_seqno
			AND a2.sorlcur_lmod_code = 'LEARNER'
			AND a2.sorlcur_cact_code = 'ACTIVE'
			AND a2.sorlcur_current_cde = 'Y'
	
		)
		
	-- Exclude VSMS programmes
	AND a1.sorlcur_program NOT LIKE ('%-V')
		
	-- Limit to specified admit term	
	AND a1.sorlcur_term_code_admit = :current_term
	
	-- Limit returned students based on start date to exclude entry points later in semester
	AND a1.sorlcur_start_date < :start_date

	-- Limit returned students based on the end date to exclude students whose end date was in the first month of semester
	AND a1.sorlcur_end_date > :expected_end_date
	
	-- Limit to specified campuses
	-- AND a1.sorlcur_camp_code IN ('OBO','OBS','DL')
    
    -- Exclude specified campuses
    AND a1.sorlcur_camp_code NOT IN ('CD', 'AIE')
	
	-- Limit to specified mode of study
	-- AND a1.sorlcur_styp_code = 'F'
    
    -- Exclude Research students
    AND a1.sorlcur_levl_code != 'RD'
	
	-- Exclude students who have a valid final enrolment status for the study path in the specified term
	AND a1.sorlcur_pidm || a1.sorlcur_key_seqno NOT IN (
	
		SELECT sfrensp_pidm || sfrensp_key_seqno
		FROM sfrensp
		WHERE
			1=1
			AND sfrensp_term_code = :current_term
			AND sfrensp_ests_code IN ('EN', 'WD', 'NS', 'AT')
	
	)
	
	-- Exclude students who have a valid final enrolment status at the learner level for the term
	AND a1.sorlcur_pidm || a1.sorlcur_key_seqno NOT IN (
	
		SELECT sfbetrm_pidm
		FROM sfbetrm
		WHERE
			1=1
			AND sfbetrm_term_code = :current_term
			AND sfbetrm_ests_code IN ('EN', 'WD', 'NS', 'AT')
	
	)
	
    -- Exclude specified students
	AND spriden_pidm NOT IN (
        SELECT glbextr_key
	    FROM glbextr
	    WHERE glbextr_selection = :exclusion_selection
        )
    
    -- Excludes anyone on a CP status in SZRENRL who still has an active learner record
   /* AND spriden_id NOT IN (
        SELECT szrenrl_student_id
        FROM szrenrl JOIN sgbstdn z1 ON z1.sgbstdn_pidm = szrenrl_pidm
        WHERE
            szrenrl_term_code = :current_term
            AND szrenrl_overall_enrol_status = 'CP'
            AND z1.sgbstdn_term_code_eff = (SELECT MAX(z2.sgbstdn_term_code_eff) FROM sgbstdn z2 WHERE z1.sgbstdn_pidm = z2.sgbstdn_pidm)
            AND z1.sgbstdn_stst_code = 'AS'
            --AND szrenrl_pidm = '1698034'
    )*/
    
    -- Pick out latest learner record
    AND b1.sgbstdn_term_code_eff = (SELECT MAX(b2.sgbstdn_term_code_eff) FROM sgbstdn b2 WHERE b1.sgbstdn_pidm = b2.sgbstdn_pidm)
    
    --AND spriden_id = '19191919'
    
    -- Limit to students without an overall enrolment status or it is CP
    AND (szrenrl_overall_enrol_status IS NULL OR szrenrl_overall_enrol_status = 'CP')
    
ORDER BY
    "Campus",
    "Programme_Code", 
    "Student_Name"    
;