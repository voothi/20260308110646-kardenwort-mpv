## REMOVED Requirements

### Requirement: Automatic Sentence Punctuation Recovery
**Reason**: Deprecated in favor of strict **Verbatim String Fidelity** (Requirement 152). Users prefer predictable exports that exactly match their selection boundaries.
**Migration**: Users must include terminal punctuation in their selection if they wish it to be exported. "Smart" restoration is removed to prevent accidental inclusion of punctuation in phrase fragments.
