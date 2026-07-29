# How to Structure Project Files for Reliable AI Collaboration

When working with an AI, the way you name and organize your files is a form of instruction. AIs don't understand context like humans; they recognize patterns. To get consistent and reliable behavior, you need to use a structure the AI is trained to recognize as important.

#### **Why Naming Conventions Matter to an AI**

An AI's understanding comes from the massive datasets it was trained on, like public code on GitHub. Through that training, it learns statistical patterns about project structure.

  * **Pattern Recognition is Everything:** The AI has learned that folders named `docs/`, `src/`, `lib/`, and files like `README.md` are statistically likely to contain crucial information. It gives them more weight.
  * **Anomalies are Ignored:** A non-standard folder name like `.sprint/`, `misc/`, or `~/.docs_for_ai/` is an outlier. The AI has no strong pattern associated with it and is likely to ignore its contents.
  * **The "Hidden" File Problem:** Folders and files starting with a dot (e.g., `.github/`, `.env`) are often treated as configuration or hidden files. Models learn to treat them as secondary context, not primary instructions.

#### **My Approach: Using `docs/` and `work/`**

I intentionally choose `docs/` and `work/` for AI-related files, even though they might already exist in a project. Here’s why:

  * **I'm leveraging the AI's bias.** I know the AI is already trained to pay close attention to anything in a `docs/` folder. Instead of fighting that bias, I use it to my advantage to ensure my instructions are seen.
  * **It creates a clear separation of concerns.**
      * `docs/`: This is where I store persistent instructions, style guides, and documentation **for the AI**.
      * `work/`: This serves as a designated "scratchpad" for the AI's output, drafts, and temporary files. It keeps the core project directories clean.

The potential for conflict with existing human-facing documentation is real, but it's easily managed. The solution is **clear subdirectories.**

**Example Structure:**

```
my_project/
├── .git/
├── src/
│   └── main.py
├── docs/
│   ├── api_reference/         # <-- For human developers
│   ├── user_guide.md          # <-- For human users
│   └── ai_guidelines/         # <-- For the AI!
│       └── coding_style.md    # <-- AI-specific instructions
└── work/
    └── ai_generated_code/     # <-- AI's scratchpad
        └── new_feature.py
```

#### **Three Rules for Reliable AI Interaction**

1.  **Use Conventional Names & Subdirectories:** Place AI-specific instructions in a dedicated subdirectory within a conventional parent folder. This gets the AI's attention without cluttering the human-facing parts of the project.

      * **Good:** `docs/ai_instructions/`
      * **Good:** `guidelines/ai/`
      * **Avoid:** `stuff_for_the_bot/`

2.  **Create a Central Instruction File:** Consolidate your core rules into a primary file, like `docs/ai_guidelines/main.md`. This makes your instructions clear and easy to reference.

3.  **Be Explicit in Your Prompt (The Golden Rule):** This is the most important step. **Never assume the AI will find the files on its own.** You must explicitly direct it.

      * **Good:**
        `"Review the rules in 'docs/ai_guidelines/coding_style.md' before you begin."`

      * **Better (for critical tasks):**
        `"Place your output in the 'work/ai_generated_code/' directory. Your code must follow every rule outlined in 'docs/ai_guidelines/coding_style.md'. Do not deviate from these instructions."`
