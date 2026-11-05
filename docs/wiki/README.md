# Copying these pages to the GitHub wiki

Each game guide is a standalone Markdown file. Its first heading is the suggested GitHub page title. Create each wiki page using that title, then paste the corresponding file's contents.

Examples:

| Local file | Wiki page title |
| --- | --- |
| `Home.md` | Home |
| `Wiki-Index.md` | Wiki Index |
| `Getting-Started.md` | Getting Started |
| `Mining-and-Tool-Progression.md` | Mining and Tool Progression |
| `Expedition-and-R0-VR.md` | Expedition and R0-VR |

For `Home.md`, keep the wiki page named **Home** even though its visible heading is **Galaxis on Fire**.

The guides link to wiki page names, such as `Farming-and-Food`, rather than to source-repository `.md` files. Preserve the suggested titles so those links resolve after all pages are created.

## One-file copy-and-paste pack

`docs/WIKI_COPY_PASTE.md` contains Home, the index, all 25 game/system guides, and optional sidebar content. Each page has its own fenced Markdown block. Copy the contents inside that block into the corresponding wiki page; do not copy the outer fence or the `Page:` separator heading.

The pack is a convenience copy. If you revise a guide afterward, update its standalone file and the relevant wiki page; the pack is not generated automatically by the game or uploader.

## Optional sidebar

`_Sidebar.md` contains navigation links for the wiki's special `_Sidebar` page. It is optional and does not replace a normal game guide.

## Publishing

Committing these files with Git Commit App stores the drafts in the game repository. GitHub's wiki is maintained separately, so that upload alone does not publish the wiki pages. Paste the guides into the wiki pages you create.

## Scope

The pages describe the current Godot game, not the original Python project. Details were checked against game scripts and current project documentation. The multiplayer guide identifies the current alpha limits. No gameplay code is changed by these files.
