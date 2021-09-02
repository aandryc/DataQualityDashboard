
/*********
FIELD_IS_STANDARD_VALID_CONCEPT

all standard concept id fields are standard and valid

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
vocabDatabaseSchema = @vocabDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
{@cohort & '@runForCohort' == 'Yes'}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
}
**********/

{@CLEANSE} ? {
	INSERT INTO @cdmDatabaseSchema.@cdmTableName_archive
		SELECT cdmTable.* 
		  FROM @cdmDatabaseSchema.@cdmTableName cdmTable
		  JOIN @vocabDatabaseSchema.concept co ON cdmTable.@cdmFieldName = co.concept_id
		  WHERE co.concept_id != 0 AND (co.standard_concept != 'S' OR co.invalid_reason IS NOT NULL); 
	
	DELETE FROM @cdmDatabaseSchema.@cdmTableName cdmTable WHERE EXISTS ( 
		SELECT 1 
		  FROM @vocabDatabaseSchema.concept co 
		  WHERE cdmTable.@cdmFieldName = co.concept_id
		    AND co.concept_id != 0 AND (co.standard_concept != 'S' OR co.invalid_reason IS NOT NULL)
	);
}

{@EXECUTE} ? {
	SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows, 
	  denominator.num_rows as num_denominator_rows
	FROM
	(
		SELECT COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
		FROM
		(
			SELECT '@cdmTableName.@cdmFieldName' AS violating_field, cdmTable.* 
			  FROM @cdmDatabaseSchema.@cdmTableName cdmTable
			  {@cohort & '@runForCohort' == 'Yes'}?{
			JOIN @cohortDatabaseSchema.COHORT c 
			ON cdmTable.PERSON_ID = c.SUBJECT_ID
			AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
			}
			  join @vocabDatabaseSchema.concept co ON cdmTable.@cdmFieldName = co.concept_id
			  WHERE co.concept_id != 0 AND (co.standard_concept != 'S' OR co.invalid_reason IS NOT NULL ) 
	  ) violated_rows
	) violated_row_count,
	( 
		SELECT COUNT_BIG(*) AS num_rows
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
		{@cohort & '@runForCohort' == 'Yes'}?{
			JOIN @cohortDatabaseSchema.COHORT c 
			ON cdmTable.PERSON_ID = c.SUBJECT_ID
			AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
			}
	) denominator;
}
