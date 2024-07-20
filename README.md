# PROSPER
I took a dataset  about a P2P loan company named "Prosper". The main goal of this project was to find main determinants of interest rate.
I uploaded either one ZIP file or as seperate functions, you can choose what you want to download :)
This is a long explanation of my project, starting from introduction, methodology and so on.
You can find data description at the end.

Now about this project :
Consumer peer-to-peer lending is rapidly gaining popularity across the globe as a compelling alternative to traditional bank loans. This modern nancial phenomenon leverages the power of technology to connect individual borrowers directly with lenders, democratizing the lending process and often enabling quicker, more exible loan arrangements. Despite its increasing adoption, there remains a considerable amount of uncertainty surrounding the determination of interest rates within this sector. Crucial criteria for setting these rates are often complex and involve factors such as credit risk assessments, market conditions, and regulatory considerations. This code explores the main interest rate determinants in the Prosper marketplace.

The advent of technology has revolutionized various sectors, including finance, leading to the emergence of innovative financial services like peer-to-peer (P2P) lending. This form of lending, which connects individual borrowers directly with individual lenders through online platforms, offers a compelling alternative to traditional bank loans. P2P lending democratizes the borrowing process, providing quicker, more flexible loan arrangements and often circumventing strict requirements imposed by conventional financial institutions. 

Consumer P2P lending has gained signifficant traction globally, driven by the need for accessible credit and the allure of potentially higher returns for lenders. However, the determination of interest rates within this sector remains a complex and somewhat of a hazy process. Unlike traditional banking, where interest rates are inuenced by institutional policies and market conditions, P2P lending platforms rely on a multitude of factors to set rates. These include the creditworthiness of borrowers, market dynamics, regulatory frameworks as well as institutional policies.

Understanding the determinants of interest rates in P2P lending is crucial for both borrowers and lenders. Borrowers seek to obtain loans at the lowest possible cost, while lenders aim to maximize their returns while mitigating risk. This code delves into the main factors influencing interest rates in the P2P lending market, using data from the Prosper marketplace prominent P2P lending platform. Our research aims to provide a comprehensive analysis of the variables that signifficantly affect interest rates in P2P lending. By examining these factors, we can offer insights into how rates are set and how various borrower characteristics and loan attributes influence borrowing costs. 


2. Main objectives of the code
The primary objective of this study is to identify and analyze the main determinants of interest rates in consumer P2P lending. Specifically, I aim to:
a.) Investigate the impact of borrower characteristics on interest rates.
b.) Examine how loan-specifc attributes infuence borrowing costs.
c.) Assess the role of external economic conditions and platform policies in interest rate determination.


Design:
This code uses some of the methods laid by  "I Just Ran Two Million Regressions Xavier X. Sala-I-Martin, published in The American Economic Review)"  study where due to an extremely large dataset, researcher takes some amount of fixed variables and runs the rest of independent variables with them always included. This reduces the run time of regressions signicantly. I used two fixed variables and the remaining ones as independent variables. My two fixed variables were Prosper Rating and Credit Score Estimated,selected based on their high R² values and significant coefficients from single-variable regressions. Each regression included three independent variables, resulting in five variables per regression. This approach was chosen due to the limited processing power of my computer, as running regressions with all variables would have been time-prohibitive.In this code, I began with a dataset containing 81 dierent variables for each loan and over one hundred thousand individual loan records. Recognizing the need for clarity and relevance, I opted to filter out less pertinent, incomplete and statistically insignifficant variables to streamline our analysis. Specifically, I removed variables such as Listing Number, Credit Grade Listing, Category (numeric), Borrower State, Occupation, Group Key, Date Credit Pulled, First Recorded Credit Line, among others. Additionally, I deleted any entries with empty values. This step ensured that our dataset remained focused on the most impactful and complete variables. I applied further filtering criteria to enhance data quality and relevance. I excluded all loans originated before August 1, 2009, as these loans had dierent data collection system, making them incompatible with the rest of the dataset. We also chose to include only loans where the income was veriable, prioritizing data validity and reliability in our analysis. To facilitate this analysis, I transformed certain variables to more applicable data types. For example, I converted the Loan Status variable from strings to boolean values, assigning a value of 1 if the loan was completed and 0 if it defaulted. I did the same with employment status data, where if a person is retired or unemployed, we assigned a boolean of 0, and 1 if they are working some hours. The reasoning behind including part-time workers and self-employed individuals was that some people are supervisory board members, where they do not work full-time but receive a solid salary from their activities. I included self-employed people primarily because of freelancers or small start-up owners. I also transformed credit score into a discrete value instead of an range. This was done with a simple mean calculation where I added the highest value of the range as well as the lowest and divided them by two. These transformation allowed for more straightforward statistical analysis and modeling. Moreover, I incorporated official Federal Reserve interest rates into our dataset. This addition was crucial for examining the relationship between P2P lending rates and Fed rates. According to standard economic theory, while the P2P market can sometimes offer lower rates than the Fed's rates, this is rarely observed in practice. P2P lending typically entails higher risks compared to government bonds, necessitating a higher risk premium for investors. This dataset corroborates this theory, as I did not observe any negative borrower rates. Consequently, I adjusted our analysis to subtract the Fed interest rate to more accurately evaluate the risk premium and its determinants.Before proceeding with my regression analysis, I ensured that our standard OLS assumptions held: 
(a) The linear regression model is linear in parameters". 
(b) There is a random sampling of observations. 
(c) The conditional mean should be zero. 
(d) There is no multi-collinearity (or perfect collinearity). 
(e) There is homoscedasticity and no autocorrelation. 
(f) Error terms should be normally distributed.
The first two assumptions held independently and were easily verified. The issue arose with the third assumption; I found that the conditional mean was approximately 0.00003, indicating a slight chance for omitted variable bias and an overestimation of our results. To check for multicollinearity, we ran a correlation analysis and found that Prosper Rating was highly positively correlated with Prosper Score.Then, conducted a Variance Inflation Factor (VIF) analysis and found that it was less than 5, thus concluding no significant multicollinearity. We checked for heteroscedasticity and found none. Finally, I verified that the error terms were normally distributed. With these validations, I proceeded with regression analysis. Final results:
Variable Mean coeffcient Sd Coeffcient
1.Intercept 0.3546 0.01698
2.Prosper rating -0.04483 0.00005
3.Credit score estimated 0.00002 0
4.Term 0.00103 0
5.Is borrower a homeowner? 0.00184 0.00029
6.Currently in a group -0.00859 0.00059
7.Current credit lines -0.00018 0.00006
8.Total credit Lines 0.00007 0.00007
9.Open revolving Accounts 0.00007 0.00019
10.Open revolving monthly payment 0 0
11.Stated monthly income 0 0
12.Current delinquencies 0.00048 0.00004
13.Delinquencies in the last 7 years 0.00007 0.00001
14.Recommendations -0.000568 0.00048

Key result interpretation:
The most significant results that contributed to reducing interest rates included the Prosper Rating, whether the borrower was in a group, recommendations, and current credit lines. Conversely, factors that increased interest rates included homeownership status, the term of the loan, and current delinquencies. For all of our 286 regressions I found that R² was between 0.89 and 0.91. I am extremely pleased with our result as such high R² value means that our dependent variables explain the absolute majority of our variance in independent variable.

The Prosper Rating was found to have a mean coefficient of -0.04483 with a standard deviation of 0.00005. This significant negative relationship indicates that higher Prosper Ratings, refecting better creditworthiness, are associated with lower interest rates. This aligns with general financial principles where lower credit risk leads to lower borrowing costs. 
Credit Score Estimated my second fixed variable, showed a mean coefficient of 0.00002, indicating a very slight positive relationship with interest rates. Although weak, this suggests that as the estimated credit score increases, the interest rate marginally increases. This counterintuitive result might be due to the interplay of other variables or specific dataset characteristics.

Homeownership Interestingly, had a mean coecient of 0.00184, suggesting a positive eect on interest rates. This could imply that homeowners are perceived as higher-risk borrowers, possibly due to the - nancial strain indicated by their need for additional funds. But research does not agree with our results.

Recommendations The variable for recommendations, had a mean coecient of -0.000568. This negative relationship indicates that more recommendations correlate with lower interest rates. Recommendations likely serve as a proxy for borrower credibility and trustworthiness in the P2P lending context

The term of the loan had a mean coefficient of 0.00103, indicating a positive relationship with interest rates. Longer loan terms generally come with higher interest rates due to the increased risk over a longer period. This is consistent with traditional finance principles, as longer loan durations entail greater uncertainty and risk for lenders.


While this code provides valuable insights into the determinants of interest rates in peer-to-peer (P2P) lending, several limitations should be acknowledged. 

Firstly, the dataset used is limited to the Prosper marketplace, which may not fully represent the broader P2P lending market, potentially affecting the generalizability of the findings. Additionally, the study relies on historical data, and the dynamic nature of economic conditions and market practices may influence the applicability of the results over time. Another limitation is the potential for omitted variable bias, as there may be relevant factors influencing interest rates that were not included in the dataset or the analysis. For example, borrower-specific qualitative factors such as the narrative provided in loan applications or lender-specific behaviors could also significantly impact interest rates but are challenging to quantify and were not considered. Furthermore, while we incorporated official Federal Reserve interest rates, the study did not account for other macroeconomic variables like inflation rates or broader financial market trends, which could also affect lending rates. Lastly, the regression models assume linear relationships between variables and interest rates, which may oversimplify the complex interactions in the real world.

Previous analysis shows that the 2 largest components of the interest rate in Prosper's P2P lending market are Term of the loan and Prosper Rating with the former indicating a positive relationship with the borrower's interest rate, the latter suggests an extremely strong negative relationship. Even though there are other statistically significant variables, their effects on expected risk and by extension the borrowers interest rate on the loan are extremely minimal. The substantial data analysed suggests, that Prosper Rating is a variable accurately explaining borrower's interest rate, and even though, the collinearity with other variables investigated was not significant, the explanation of an extremely significant Prosper Rating's results can lie in the composition of this variable.
