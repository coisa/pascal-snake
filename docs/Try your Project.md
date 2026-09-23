# How far can your AI take your college project?

The author confirmed that this Snake began as a university project. The
experiment started with a simple prompt to explore what a modern frontier AI
could do with it. This reusable prompt captures the challenge; it is not
presented as a verbatim transcript of the original request.

Replace the brackets, provide the repository, and try:

> This is a project I made at university: [project and purpose].
>
> Modernize it into the best usable version you can build today, while keeping
> [original language] as the foundation. The original constraints were
> [constraints]. Preserve the idea and make the implementation something I can
> still study and recognize.
>
> Start by running or inspecting the original. Explain its real limitations.
> Then implement the improvements: strengthen correctness, rethink the user
> experience, add thoughtful visual and interaction design, and go beyond a
> cosmetic cleanup. Use modern libraries when they help, but keep the actual
> application in the required language.
>
> Make it easy to build and run. Add meaningful deterministic tests and test
> the interaction, failure paths and final package. Show me the actual result,
> not a mockup. Inspect the rendered interface and fix clipping, confusing
> controls and broken states. Do not claim tests or platform support you did
> not verify.
>
> Write the interface and documentation in English. Explain that this is an
> experiment with my college project and describe the important decisions so
> another student can learn from them. Preserve the original through Git.
>
> Work autonomously on reversible local changes. Ask before external
> publication, spending money, installing shared tools or destructive actions
> that I have not authorized. Finish with the runnable result, test evidence,
> known limitations and a concise explanation of what improved.

## Compare the results

Give different tools the same starting commit and constraints. Record the
model/tool version, date, time and follow-up prompts. A useful comparison asks:

- Does it build from a clean checkout using the documented commands?
- Does the core behavior work, including edge cases and failure paths?
- Is the experience coherent and pleasant beyond the first screenshot?
- Did it keep the language constraint and preserve an understandable design?
- Are the tests meaningful, and are limitations stated honestly?
- Can you explain the implementation after reading it?

Avoid calling one impressive demo the universally best AI. Different tools,
budgets and follow-up instructions can produce different outcomes. Keep your
own judgment in the loop.
