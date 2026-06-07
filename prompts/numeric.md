You are writing a SELF-CONTAINED Python script that numerically evaluates the
formula below using the given numbers, so the result can be checked against the
paper's reference value by ACTUAL computation (not by your own estimate).

FORMULA / QUANTITY (from the paper):
---
{{CLAIM}}
---

DEFINITIONS / SYMBOLS:
---
{{CONTEXT}}
---

NUMERICAL INPUTS AND THE PAPER'S REFERENCE VALUE:
---
{{NUMBERS}}
---

Write Python that:
- uses ONLY the standard library `math` (and `cmath` if truly needed) — no other
  imports, no file access, no I/O beyond `print`
- assigns the given numbers to clearly named variables
- evaluates the formula
- prints ONLY the final numeric result on the last line, in scientific notation,
  e.g.  `print(f"{result:.4e}")`  — nothing else on that line

Output ONLY the code, inside one fenced block:

```python
# your code here
```

Do not add prose before or after the code block. Do not print labels or units on
the result line — just the number.
