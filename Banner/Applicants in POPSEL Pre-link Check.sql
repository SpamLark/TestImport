SELECT DISTINCT
    SARADAP_PIDM AS "PIDM",
    SPRIDEN_ID AS "BANNER_ID",
    SARADAP_APPL_NO AS "APPLICATION_NUMBER",
    SARADAP_TERM_CODE_ENTRY AS "ADMIT_TERM",
    SARADAP_STYP_CODE AS "MODE_OF_STUDY",
    SARADAP_RESD_CODE AS "RESIDENCY",
    SARAPPD_APDC_CODE AS "APPLICATION_DECISION",
    SARAPPD_APDC_DATE AS "APPLICATION_DECISION_DATE",
    SARAPPD_SEQ_NO AS "APPLICATION_SEQ_NO",
    SARADAP_PROGRAM_1 AS "APPLICATION_PROGRAMME_CODE",
    SARAATT_ATTS_CODE AS "STUDENT_ATTRIBUTE",
    SARCHRT_CHRT_CODE AS "COHORT_CODE",
    SORLCUR_PROGRAM AS "CURRICULUM_PROGRAMME_CODE",
    SORLCUR_CURR_RULE AS "CURRICULUM_RULE",
    SOBCURR_PROGRAM AS "SOBCURR_PROGRAMME",
    SORLFOS_MAJR_CODE AS "MAJOR",
    SMRPRLE_PROGRAM_DESC AS "PROGRAMME_DESCRIPTION"
FROM
    SARADAP -- Application Table
    JOIN SPRIDEN ON (SARADAP_PIDM = SPRIDEN_PIDM)
    JOIN SARAPPD s1 ON (SARADAP_PIDM = SARAPPD_PIDM AND SARADAP_APPL_NO = SARAPPD_APPL_NO) -- Application Decision Table
    LEFT JOIN SARAATT ON (SARADAP_PIDM = SARAATT_PIDM AND SARADAP_APPL_NO = SARAATT_APPL_NO) -- Applicant Attribute Table
    LEFT JOIN SARCHRT ON (SARADAP_PIDM = SARCHRT_PIDM AND SARADAP_APPL_NO = SARCHRT_APPL_NO) -- Applicant Cohort Table
    JOIN SORLCUR ON SARADAP_PIDM = SORLCUR_PIDM AND SARADAP_APPL_NO = SORLCUR_KEY_SEQNO AND SORLCUR_LMOD_CODE = 'ADMISSIONS' -- Curriculum Table
    JOIN SMRPRLE ON SARADAP_PROGRAM_1 = SMRPRLE_PROGRAM -- Programme Table for description
    JOIN SORLFOS ON SORLCUR_PIDM = SORLFOS_PIDM AND SORLCUR_SEQNO = SORLFOS_LCUR_SEQNO -- SORLFOS for Major
    LEFT JOIN SOBCURR ON SORLCUR_CURR_RULE = SOBCURR_CURR_RULE -- Check that SORLCUR_CURR_RULE is correct
WHERE
    1=1
    AND s1.sarappd_seq_no = (
        SELECT MAX(s2.sarappd_seq_no)
        FROM sarappd s2
        WHERE s2.sarappd_pidm = s1.sarappd_pidm and s2.sarappd_appl_no = s1.sarappd_appl_no)
    AND SARAPPD_APDC_CODE = 'UT'
    AND SARADAP_APST_CODE != 'W'
    AND SARADAP_TERM_CODE_ENTRY = '201909'
    AND spriden_change_ind is null
    AND sorlcur_current_cde = 'Y'
    AND SARADAP_RESD_CODE != '0'
    AND saraatt_atts_code is not null
    AND sorlcur_curr_rule is not null
    AND sobcurr_program != 'DO NOT USE'
    AND saradap_program_1 = sorlcur_program
    AND SMRPRLE_PROGRAM_DESC != 'DO NOT USE'
    AND SMRPRLE_PROGRAM_DESC != 'NOT IN USE'
    --AND saradap_pidm = '1239915'
    --AND saradap_pidm in (SELECT GLBEXTR_KEY FROM GLBEXTR WHERE GLBEXTR_SELECTION = 'SRC_LINK')
ORDER BY
      SPRIDEN_ID
