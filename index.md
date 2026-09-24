What’s inside

01

### Load once per run

`run_all()` loads each dataset once and passes it to every analysis.

02

### Argsets from combinations

[`expand_list()`](https://www.rwhite.no/plnr/reference/expand_list.md)
makes one argset for each combination of strata, exposures or outcomes.
One action function then covers them all.

03

### Sequence or parallel

Run the analyses in sequence, or in parallel through a foreach backend.
The results come back as one list.
