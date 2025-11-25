
# Use of LLMs in Project #4 (Gopher Hunt Game)

## (a) List the LLM or LLMs that you used for this project

For this project I used **ChatGPT (OpenAI)**, specifically the **GPT-5.1 Thinking** model, as my LLM assistant.

## (b) Did you use an LLM for refining the spec or project code or both?

I used the LLM for **both**:

- **Refining the spec**  
  I started from the rough spec in the PDF and asked the LLM to help me turn it into a more detailed, structured refined specification that matches my actual UI and classes.

- **Project code**  
  I asked for help designing the UI layout (two 8×8 boards, status area, log area) and fixing layout issues like BOTTOM OVERFLOW errors.  
  I also used it to reason about how to structure the main game loop and how to connect the players, controller, and UI.

## (c) What kind of prompting did you use for LLM?

I mostly used:

- **Chain-of-thought prompting**  
  I described the problem, shared my current code, and asked the LLM to walk through problems step by step (for example, debugging layout, thinking about state updates, and designing the heuristics conceptually).

- **Iterative prompting / refinement** (informal few-shot)  
  I provided examples of what I already had (e.g., an initial `main.dart`, existing widgets) and asked the LLM to modify or refine them instead of starting from scratch.

- **Zero-shot prompting**  
  For short questions (e.g., “What does this Flutter error mean?”), I sometimes just asked the question without giving much extra context.

## (d) Likert rating of LLM results

On a 1–5 scale (5 = exact, 1 = not helpful), I would rate this LLM as:

- **ChatGPT (GPT-5.1 Thinking): 4**  

Most of the time the suggestions were directly useful and close to correct. I still had to:

- Run the app,
- Adjust widget sizes and layout constants for my specific emulator, and
- Make small changes so that the specs, UI, and code all match exactly.

Overall, the LLM saved me time, especially with UI structure and thinking through the game loop.
