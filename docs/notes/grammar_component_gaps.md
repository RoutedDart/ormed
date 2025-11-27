# Laravel Grammar Component Gaps

While reviewing `Illuminate\Database\Query\Grammars\Grammar.php` we noted the following
areas where our `QueryGrammar` diverges:

1. **Component Pipeline** – Laravel iterates over `selectComponents` and invokes
   compile methods (`compileColumns`, `compileFrom`, `compileJoins`, `compileWheres`,
   etc.) in order. Our `_SelectCompilation` emits a single SQL string so we cannot
   intercept intermediate clauses (e.g., to rewrite HAVING + UNION combinations).
2. **Union Aggregates** – Laravel detects `($query->unions || $query->havings) &&
   $query->aggregate` and routes through `compileUnionAggregate`, ensuring each
   SELECT is wrapped via `wrapUnion(...)`. We currently append unions after the
   final SQL buffer, which breaks when HAVING or aggregate clauses need
   rewriting.
3. **Distinct-On & Column Normalization** – Laravel’s pipeline revisits columns
   when `distinct` is an array, while our implementation only injects `DISTINCT`
   at the `compileColumns` entry point.

These gaps drive the new union/aggregate tasks tracked under
`openspec/changes/plan-grammar-instrumentation/`.
