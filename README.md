# using_PCA_to_categorize_skills
 
 ## Goal
 
 This project aims to categorize the test items of ASVAB test into several main categories for interpretation and further examination. The code is in **main_asvab_pca.do**.
 
 
 ## What is ASVAB test?
The ASVAB, or Armed Services Vocational Aptitude Battery, is a standardized test used by the United States military to assess and predict a person's aptitude for various military jobs and specialties. The test measures a candidate's knowledge and abilities in different areas and helps the military determine which roles they are best suited for. The ASVAB is administered by the Department of Defense and is primarily used for enlistment purposes.

## Where does the data come from?
The NLSY79 collected information about a variety of standardized achievement tests commonly taken by young adults in junior high school and high school. The Transcript Survey is a 1980-83 collection of high school transcript information, which included the gathering of math and verbal scores from such tests as the Preliminary Scholastic Aptitude Test (PSAT), the Scholastic Aptitude Test (SAT), and the American College Test (ACT). The High School Survey is a 1980 survey of high schools, which used school records to collect scores from various aptitude/intelligence tests and college entrance examinations administered during the youth's high school career. Finally, during the summer and fall of 1980, NLSY79 respondents participated in an effort of the U.S. Departments of Defense and Military Services to update the norms of the Armed Services Vocational Aptitude Battery (ASVAB).

## Output
I output pictures of [factor loadings](https://github.com/wangshasha111/using-Principal-Component-Analysis-to-categorize-skills/blob/main/asvab_loadings_4comp.png) and the [scree plot](https://github.com/wangshasha111/using-Principal-Component-Analysis-to-categorize-skills/blob/main/asvab_scree_var.png) to examine the principal components.

## Takeaways
The about 10 test items can be categorized into five categories: math, verbal, science, mechanical, and administrative. This is the base for my further research using machine learning methods to study gender differences.



