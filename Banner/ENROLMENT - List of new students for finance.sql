/*

List of new students for finance

*/

SELECT DISTINCT
    d1.spriden_id AS "Student_ID",
    t1.sgrstsp_pidm AS "Student_PIDM",
    d1.spriden_last_name AS "Last_Name", 
    d1.spriden_first_name AS "First_Name",
    t1.sgrstsp_key_seqno AS "Study_Path",
    --t1.sgrstsp_term_code_eff,
    --t1.sgrstsp_stsp_code,
    t2.sorlcur_term_code_admit AS "Admit_Term",
    t4.sgbstdn_resd_code AS "Residency",
    --t2.sorlcur_key_seqno,
    --t2.sorlcur_priority_no,
    t2.sorlcur_coll_code AS "Faculty",
    t2.sorlcur_levl_code AS "Level",
    t2.sorlcur_program AS "Programme",
    t2.sorlcur_styp_code AS "Mode_of_Study",
    t2.sorlcur_start_date AS "Start_Date",
    t2.sorlcur_end_date AS "Expected_End_Date",
    --t2.sorlcur_term_code AS "Sorlcur_Term_Code",
    --t2.sorlcur_term_code_end AS "Sorlcur_Term_Code_End",
    --t2.sorlcur_curr_rule,
    --t3.sorlfos_csts_code,
    --t4.sgbstdn_term_code_eff,
    --tbraccd_detail_code,
    (
    	SELECT SUM(tbraccd_amount) 
    	FROM tbraccd 
    	WHERE 
    		t1.sgrstsp_pidm = tbraccd_pidm  
    		AND (tbraccd_term_code = :term_for_enrolment)
    		AND TBRACCD_DETAIL_CODE IN (
    			SELECT TBBDETC_DETAIL_CODE 
    			FROM TBBDETC 
    			WHERE TBBDETC_DCAT_CODE = 'TUI'
    			)
    ) AS "Term_1_Fees",
    (
    	SELECT SUM(tbraccd_amount) 
    	FROM tbraccd 
    	WHERE 
    		t1.sgrstsp_pidm = tbraccd_pidm  
    		AND (tbraccd_term_code = :term_for_enrolment_plus_1)
    		AND TBRACCD_DETAIL_CODE IN (
    			SELECT TBBDETC_DETAIL_CODE 
    			FROM TBBDETC 
    			WHERE TBBDETC_DCAT_CODE = 'TUI'
    			)
    ) AS "Term_2_Fees",
    (
    	SELECT SUM(tbraccd_amount) 
    	FROM tbraccd 
    	WHERE 
    		t1.sgrstsp_pidm = tbraccd_pidm  
    		AND (tbraccd_term_code = :term_for_enrolment_plus_2)
    		AND TBRACCD_DETAIL_CODE IN (
    			SELECT TBBDETC_DETAIL_CODE 
    			FROM TBBDETC 
    			WHERE TBBDETC_DCAT_CODE = 'TUI'
    			)
    ) AS "Term_3_Fees"
    --t4.acenrol_status_1,
    --t4.finenrol_status_1,
    --t4.overall_enrol_status_1
FROM
    sgrstsp t1
    JOIN sorlcur t2 ON (t1.sgrstsp_pidm = t2.sorlcur_pidm AND t1.sgrstsp_key_seqno = t2.sorlcur_key_seqno)
    JOIN sorlfos t3 ON (t2.sorlcur_pidm = t3.sorlfos_pidm AND t2.sorlcur_seqno = t3.sorlfos_lcur_seqno)
    JOIN spriden d1 ON (t1.sgrstsp_pidm = d1.spriden_pidm)
    JOIN sgbstdn_add t4 ON (t1.sgrstsp_pidm = t4.sgbstdn_pidm)
    LEFT JOIN tbraccd ON tbraccd_pidm = t1.sgrstsp_pidm
    LEFT JOIN szrenrl z1 ON t1.sgrstsp_pidm = z1.szrenrl_pidm
WHERE
    1=1
  
	-- CURRENT STUDENT NUMBER AND NOT TEST
    AND d1.spriden_change_ind IS NULL
    AND (d1.spriden_ntyp_code IS NULL OR d1.spriden_ntyp_code != 'TEST')
    
	-- IDENTIFY STUDENTS WITH ACTIVE STUDY PATHS
    AND t1.sgrstsp_term_code_eff = (
        SELECT MAX(a2.sgrstsp_term_code_eff)
        FROM sgrstsp a2
        WHERE t1.sgrstsp_pidm = a2.sgrstsp_pidm AND t1.sgrstsp_key_seqno = a2.sgrstsp_key_seqno
    )
    AND t1.sgrstsp_stsp_code = 'AS'
    
    -- Exclude AIE students
    AND t2.sorlcur_camp_code NOT IN ('AIE')
    
	-- LIMIT TO CURRENT SGBSTDN RECORD
    AND t4.sgbstdn_term_code_eff = (
        SELECT MAX(e2.sgbstdn_term_code_eff)
        FROM sgbstdn e2
        WHERE t4.sgbstdn_pidm = e2.sgbstdn_pidm
    )
    AND sgbstdn_stst_code = 'AS'
    
	-- ONLY INCLUDE PROPER SORLCUR RECORDS
    AND t2.sorlcur_lmod_code = 'LEARNER'
    AND t3.SORLFOS_csts_code = 'INPROGRESS'
    AND t2.sorlcur_current_cde = 'Y'
    AND t2.sorlcur_term_code_end IS NULL
    
	-- EXCLUDE STUDENTS WHO ARE ALREADY EN/AT/UT/WD FOR THE ENROLMENT TERM
    AND t1.sgrstsp_pidm NOT IN (
        SELECT sfrensp_pidm FROM sfrensp WHERE sfrensp_term_code = :term_for_enrolment AND sfrensp_ests_code IN ('AT', 'EN', 'UT', 'WD', 'XF')
    )
    
	-- LIMIT TO NEW STUDENTS
    AND t2.sorlcur_term_code_admit = :term_for_enrolment
    
	-- ONLY INCLUDE STUDENTS WHO HAVE NOT BEEN OPENED FOR ENROLMENT YET
	-- AND t4.acenrol_status_1 IS NULL
	-- AND spriden_id = '17088151'
    
    -- Enrolment 
    AND (z1.szrenrl_term_code = (
    
    	SELECT MAX(z2.szrenrl_term_code)
    	FROM szrenrl z2
    	WHERE z1.szrenrl_pidm = z2.szrenrl_pidm AND z1.szrenrl_study_paths = z2.szrenrl_study_paths
    
    ) OR z1.szrenrl_term_code IS NULL)
    --AND spriden_id = '19148019'
    
ORDER BY
    sorlcur_program,
    sorlcur_end_date ASC
;