This comprehensive documentation serves as the technical and conceptual manual for the **Delhi Environmental Health Economics Analytics** dashboard. It is designed to bridge the gap between environmental data science and public health policy.

------------------------------------------------------------------------

## 1. Project Overview

The dashboard is a simulation tool that estimates the **Economic Health Burden** (treatment costs and productivity loss) caused by environmental stressors in the National Capital Territory (NCT) of Delhi. It allows users to manipulate environmental variables and policy interventions to see real-time shifts in health-related expenditures.

------------------------------------------------------------------------

## 2. Theoretical Framework & Baseline

The model is built on a **Cost-of-Illness (COI)** framework.

### The Baseline Data (`base_costs`)

The app uses a synthetic baseline representing the "Normal" economic cost (in INR Crores) for 8 specific health conditions under "Monsoon" conditions (the cleanest air season in Delhi).

| Health Condition   | Base Cost (Cr) | Primary Driver                  |
|:-------------------|:---------------|:--------------------------------|
| Respiratory/Asthma | High           | Particulate Matter ($PM_{2.5}$) |
| Cardiovascular     | High           | Systemic Inflammation           |
| Heat Stroke        | Low (Baseline) | Ambient Temperature             |
| Mental Health      | Medium         | Chronic Stress/Pollution        |

### Geographic Normalization (`district_weights`)

Costs are adjusted using **Geographic Coefficients**. Since population and healthcare infrastructure vary across Delhi, a weight is assigned to each of the 11 districts (e.g., North-West Delhi is weighted higher at **0.135** due to population density, while New Delhi is lower at **0.035**).

------------------------------------------------------------------------

## 3. Mathematical Logic & Modeling

The core engine of the app uses a **Multi-Factor Stochastic Model** to calculate the final economic impact.

### A. The Environmental Multiplier Logic

The "Gross Cost" is not static. It scales based on the selected season using a `switch` logic: $$\text{Gross Cost} = (\text{Base Cost} \times \text{Seasonal Multiplier} \times \text{District Weight}) \times 11$$

-   **Winter Multiplier:** Can scale costs up to **3.8x** for COPD due to the "Smog Season."
-   **Heat Multiplier:** Scales Heat Stroke costs by **3.2x** during Summer.
-   **AQI Override:** A final linear multiplier ($0.5x$ to $3.0x$) is applied to simulate specific "Peak Pollution" events.

### B. The Mitigation Model (Synergistic Reduction)

The app models policy interventions (like the *Odd-Even Rule* or *Construction Bans*) using the **Law of Diminishing Returns**.

When multiple strategies are selected, the app does not add them; it multiplies the "survival" probability of the cost: $$\text{Total Reduction} = 1 - \prod_{i=1}^{n} (1 - R_i)$$ *Where* $R_i$ is the reduction efficiency of strategy $i$.

**Example:** If Strategy A reduces risk by 20% and Strategy B by 10%, the total reduction is **28%** ($1 - (0.8 \times 0.9)$), not 30%. This reflects the real-world overlap where different policies target the same emission sources.

### C. The Resilience Floor

The model includes a hard-coded "Ceiling of Effectiveness" using `pmin(total_red, 0.85)`. This assumes that even with perfect environmental policy, **15% of the health cost is "Inelastic"** and cannot be removed (due to genetics, age, or non-environmental factors).

------------------------------------------------------------------------

## 4. Architecture & Tech Stack

### Frontend (UI)

-   **Theme:** Professional Light (Clean Sans-Serif).
-   **Typography:** **Inter** for UI elements (legibility) and **Roboto** for data/numbers (tabular alignment).
-   **Grid System:** Uses CSS Flexbox and CSS Grid for a responsive sidebar-to-content ratio.

### Backend (Server)

-   **Reactive Programming:** Uses `eventReactive` triggered by an `actionButton`. This ensures the server only computes heavy matrices when the user is ready, optimizing performance.
-   **Data Reshaping:** Uses `tidyr::pivot_longer` to transform wide-format economic data into long-format for `ggplot2` rendering.

------------------------------------------------------------------------

## 5. Visual Analytics Logic

-   **Heatmaps:** Use `expand.grid` to calculate the "Full Risk Surface," showing the user where the highest cost intersections exist across all four seasons simultaneously.
-   **Radar/Spider Charts:** Visualize the "Balance of Burden." By closing the polygon loop (`idx <- c(1:n, 1)`), the app provides a geometric representation of how mitigation "shrinks" the health burden area.
-   **KPI Tracking:** Real-time summation of vectors to provide four "Executive Insights": Gross Impact, Mitigated Cost, Total Savings, and the % Efficiency of current policies.

------------------------------------------------------------------------

## 6. Deployment & Reproducibility

The app is designed to be a "Single File Shiny App" (`app.R`). \* **Dependencies:** `shiny`, `plotly`, `ggplot2`, `DT`, `dplyr`. \* **Input Data:** Currently uses an internal dataframe based on epidemiological averages for the Delhi NCR region.

------------------------------------------------------------------------

### Final Research Significance

This model serves as a **Decision Support System (DSS)**. It demonstrates that the "Cost of Inaction" (Gross Cost) during a Delhi winter far exceeds the "Cost of Implementation" for aggressive mitigation strategies, providing a clear economic argument for public health intervention.
