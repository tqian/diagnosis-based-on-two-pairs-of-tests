# Diagnosis Algorithm Repository

A lightweight R implementation of a diagnosis algorithm based on paired positive test results (Test A and Test B). This repository includes example data, the core function implementation, visualization scripts, and a suite of tests for edge and missing-case scenarios.

## Repository Structure

```
├── example data and function use.R     # Example dataset and algorithm implementation
├── visualize data set.R               # Visualization of test dates and diagnoses
├── testing - edge cases.R             # Edge-case tests for boundary conditions
├── testing - missing cases.R          # Tests for scenarios with insufficient data
├── doc_logic.png                      # Flowchart of the diagnostic logic
├── doc_algorithm.png                  # Diagram of the algorithm implementation
└── README.md                          # This documentation
```

## Prerequisites

- **R** (version >= 4.0)
- **R packages**:
  - tidyverse

Install required packages:
```r
install.packages("tidyverse")
```

## Usage

1. **Run the example and algorithm**
   ```r
   source("example data and function use.R")
   # This loads example data and defines `assign_diagnosis()`
   diagnose_df <- assign_diagnosis(example_data)
   head(diagnose_df)
   ```

2. **Visualize results**
   ```r
   source("visualize data set.R")
   # Generates a timeline plot of Test A and Test B positives,
   # highlighting the pairs used for positive diagnoses.
   ```

3. **Testing**
   - **Edge-case tests**:
     ```r
     source("testing - edge cases.R")
     # Verifies boundary conditions (e.g., 90-day, 365-day gaps)
     ```
   - **Missing-case tests**:
     ```r
     source("testing - missing cases.R")
     # Checks behavior when individuals lack sufficient test records.
     ```

## Documentation

- **Diagnostic logic flowchart**: `doc_logic.png`

  ![Logic Flowchart](doc_logic.png)

- **Algorithm implementation diagram**: `doc_algorithm.png`

  ![Algorithm Diagram](doc_algorithm.png)

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for bug fixes, enhancements, or additional test cases.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
