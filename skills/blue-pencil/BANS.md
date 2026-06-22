# Blue Pencil: the ban list

Distilled for product copy and user-facing docs from a longer prose-craft guide and from validated UX-writing practice. Each entry is **pattern / why it fails / do instead**. Two reminders from [SKILL.md](SKILL.md): hunt density, not single instances, and defer to the project's own rubric, which may legitimately sanction some of these.

## 1. AI vocabulary cluster

Words overrepresented in model output. A cluster of them means the copy regressed to the statistical mean.

delve, leverage (verb), utilize, seamless, robust, comprehensive, unlock, empower, harness, navigate (as metaphor), foster, showcase, streamline, elevate, supercharge, effortless, cutting-edge, best-in-class, game-changing, holistic, synergy, ecosystem (as metaphor), curated, tailored, bespoke (as filler), realm, landscape (figurative), tapestry, journey (as metaphor).

**Why:** they sound important without being specific; they fit any product, so they describe none.
**Do instead:** say the literal action or benefit. Not "leverage our platform to streamline workflows" but "import a CSV and it sorts the rows for you."

## 2. Importance and legacy puffery

stands as a testament to, a testament to, serves as a reminder, enduring/lasting legacy, lasting impact, plays a vital/pivotal/crucial role, of paramount importance, cannot be overstated, at the forefront of, in today's fast-paced world, more important than ever.

**Why:** they assert significance instead of demonstrating it.
**Do instead:** show the consequence and let the reader judge importance. Cut the meta-claim.

## 3. Promotional / brochure language

nestled (unless literal geography), in the heart of, boasts (a feature), stunning, breathtaking, rich tapestry of, vibrant (community/ecosystem), bustling, picturesque, idyllic, continues to captivate, world-class, one-stop shop, look no further, dive in, take it to the next level.

**Why:** advertising words that tell the reader to be impressed rather than earning it.
**Do instead:** one concrete detail beats five adjectives. Replace "stunning, world-class dashboard" with what the dashboard actually shows.

## 4. Self-praise product adjectives

simple, easy, powerful, seamless, intuitive, effortless, smart, magical, delightful, robust, flexible (as a claim about your own product).

**Why:** delivering the experience is the writer's job, not asserting it. "Simple" copy on a confusing screen reads as a lie.
**Do instead:** show it. If it's simple, a three-word instruction proves it. Don't say "powerful filtering"; show the filter doing something specific.

## 5. False range ("from X to Y")

"from setup to scale," "from beginners to experts," "from idea to launch," "from the boardroom to the break room."

**Why:** sounds comprehensive, means nothing; often X and Y aren't even on one scale. Borrowed from ad copy, where vagueness is the feature.
**Do instead:** if there's no real middle point between the endpoints, cut the construction and name the actual span.

## 6. Formulaic parallelism

"not only X, but Y," "it's not about X, it's about Y," "X isn't just Y. It's Z."

**Why:** performs depth through syntax; the second clause usually just reinflates the first. Heavily overrepresented in model output.
**Do instead:** state the point once, directly. If both clauses carry real information, make them two plain sentences.

## 7. Simile-as-adverb

"with the precision of a surgeon," "with the confidence of someone who's done this a thousand times," "like a [noun] [verb]ing."

**Why:** invents a hypothetical person to avoid describing the real behavior. Feels specific without being specific.
**Do instead:** describe what the thing actually does.

## 8. Narrator-as-analyst participles

"..., highlighting the value," "..., underscoring our commitment," "..., reflecting the team's care," "..., ensuring a smooth experience."

**Why:** the sentence stops to explain its own significance. Classic tell: a feature "highlighting" or "underscoring" something.
**Do instead:** delete the participle. If the fact needs an interpreter, the fact is underwritten.

## 9. Rule-of-three lists

Three parallel items where two or four would be natural ("fast, simple, and powerful").

**Why:** the triad is a rhythm models reach for reflexively; readers now hear it as filler.
**Do instead:** use the number of items you actually have. Two is fine. Four is fine. Don't pad to three.

## 10. "-ing" sentence openers (overuse)

"Empowering teams to...", "Helping you...", "Unlocking...", "Bringing your data to life."

**Why:** the participial opener is a marketing reflex and a model default; a page of them reads identical.
**Do instead:** lead with the subject doing the thing. "Your team ships faster" beats "Empowering your team to ship faster."

## 11. Em-dash discipline

Readers now pattern-match the prose em dash to AI text. Avoid it in user-facing copy.

**Do instead:** a period, comma, colon, or parenthesis, and vary which one. The "statement, then elaboration" cadence is the real tell; swapping the punctuation but keeping the cadence doesn't fix it. (En dashes in number ranges like "12–20" and structural label separators are typography, not prose, and are fine.)

## 12. Over-explanation

Defining a term the surrounding UI already makes obvious; restating the button label in the helper text.

**Why:** padding that talks down to the reader.
**Do instead:** trust the interface. Cut anything the screen already says.

## 13. Hedged non-positions and empty reassurance

"rest assured," "don't worry," "simply," "just," "easily," "of course," "needless to say," "in order to," and vague comfort the product can't back up.

**Why:** filler and unearned reassurance. "Simply / just / easily" also quietly blame the user when the step turns out not to be simple.
**Do instead:** cut the hedge. State the step plainly. Reassure with a fact, not an adjective.

---

## Quick-scan table

Grep these against a draft or a corpus. A single hit is usually fine; clusters are the target.

| Search for | Action |
|---|---|
| delve, leverage, seamless, robust, comprehensive, unlock, empower, harness, navigate, foster, showcase, streamline, elevate, holistic | Replace with the literal action or benefit |
| testament to, enduring legacy, vital/pivotal/crucial role, cannot be overstated, in today's world | Cut the significance claim; show consequence |
| nestled, boasts, stunning, breathtaking, vibrant, world-class, dive in, look no further | Replace with one concrete detail |
| simple, easy, powerful, seamless, intuitive, effortless (about your own product) | Show it; delete the adjective |
| from X to Y | Check for a real scale; if none, cut |
| not only... but, it's not about X it's about Y, isn't just... it's | State once, directly |
| with the [noun] of, like a [noun] [verb]ing | Describe the actual behavior |
| highlighting, underscoring, reflecting, ensuring, emphasizing (trailing participle) | Delete the editorial participle |
| three-item parallel lists | Use the real count, not three |
| sentence-initial -ing (Empowering, Helping, Unlocking) | Lead with the subject |
| prose em dash | Period / comma / colon / parenthesis, varied |
| simply, just, easily, rest assured, in order to | Cut the hedge; state the step |
