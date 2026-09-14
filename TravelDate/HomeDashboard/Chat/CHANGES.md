# Chat Media Fix — Summary

## Root cause
`ChatMessageCell` sized its attachment container only *after* the image/
video finished loading (Kingfisher success callback / thumbnail
generation), starting hidden with an inactive width constraint. Row
height was therefore a function of "did the async load finish yet", not
of the message data itself — which is exactly what produces the jumping /
overlapping rows under scrolling, pagination, and fast sends.

Secondary bugs found in the audit: three inconsistent URL-resolution
implementations, a force-unwrap crash on image preview, a main-thread
blocking video read, fragile query-param-unsafe video detection, and no
scroll-position anchoring during pagination.

## Files changed (9)
1. **ChatMediaURL.swift** — NEW. Single URL resolver used by every
   loader (images, avatars, video thumbnails, video playback).
2. **ChatMessageCell.swift** — Core fix. Attachment container is now
   sized synchronously in `configure(with:)`: real size if known
   (local pick), else a remembered aspect ratio (in-memory
   `NSCache<NSString, NSNumber>` keyed by media URL), else a stable
   16:9 fallback. Real media loads async and just paints into the
   already-correct box; a row re-measure only happens on the rare
   "guessed wrong" correction, and the real ratio is cached so that
   media never guesses again. Also: `attachmentMaxWidthRatio` 0.62→0.68,
   `attachmentMaxHeight` 240→300, avatar loads via `ChatImageLoader`
   (was inconsistent inline `URL(string:)`), long-press disabled for
   videos.
3. **ChatMessageVc.swift** — Pagination scroll-offset anchoring
   (content-size delta preserves visual position when older messages
   prepend); removed `ImagePreviewVC(image: image!)` force-unwrap;
   moved video file read off the main thread.
4. **ChatViewModel.swift** — `loadOlderIfNeeded()` now returns whether
   it actually started a fetch; added `onOlderPrepended` callback
   distinct from `onReload` so the VC only anchors scroll on actual
   pagination, not every reload. No other architecture changes.
5. **ChatModels.swift** — `ChatMediaKind.isVideo` now parses the URL via
   `URLComponents` before reading the extension (safe with query
   params like `?token=123`) and checks a backend type hint first if
   ever provided.
6. **ChatImageLoader.swift** — Routes through `ChatMediaURL`; re-enabled
   the cache (was dead code — read was commented out).
7. **ChatVideoThumbnailLoader.swift** — Routes through `ChatMediaURL`;
   tries a second timestamp (0s) if 0.1s has no frame.
8. **ChatVideoPlayerPresenter.swift** — Routes through `ChatMediaURL`.

## Post-delivery fix
Crash: `NSInternalInconsistencyException ... attempt to insert row 3
into section 1, but there are only 1 sections after the update`. Cause:
`onAttachmentSizeResolved`'s handler hopped through an extra
`DispatchQueue.main.async` before re-deriving the cell's index path —
both Kingfisher's and `ChatVideoThumbnailLoader`'s completions already
run on main, so that hop only opened a window for `viewModel.sections`
to change shape before the captured index path was used. Fixed in
**ChatMessageVc.swift**: the async hop is gone, and the index path is
now validated against the current `viewModel.sections` bounds before
`reloadRows(at:)` is called — if it's gone stale, the (rare, cosmetic)
correction is simply skipped rather than crashing; the cell itself
already shows the right size regardless.

## Post-delivery fix #2
Logs showed `Unable to simultaneously satisfy constraints` firing
repeatedly with `<UIImageView.height == 300 (active)>` (or `190.4`) in
the conflict set, and `Will attempt to recover by breaking constraint
<...height == 300>` — meaning UIKit sometimes discarded our OWN image
height constraint during UITableView's self-sizing measurement pass,
not just some unrelated internal one. Root cause: `attachmentWidthConstraint`
/ `attachmentHeightConstraint` were `.required` (1000) priority, same as
the temporary `UIView-Encapsulated-Layout-Height` constraint UITableView
applies to contentView (at the smaller estimated height) while measuring
— two required constraints that can't both hold force Auto Layout to
break one, and which one gets broken isn't guaranteed. Fixed in
**ChatMessageCell.swift**: both constraints are now priority 999 (one
below required), so it's always ours that flexes during that one
transient pass — harmlessly, since the pass that actually determines the
final row height still resolves to the correct size.

## Post-delivery fix #3 (screen recording)
Recording showed text bubbles wrapping character-by-character ("Bhis /
dkm", "Dds / dds / dsd...") and getting cut off entirely after a few
lines — plus, in the same broken state, a patch of a completely
different screen's content visible through the chat (both symptoms of
the same underlying cause: wrong row-height measurement leaving a
mismatched/empty region that the transparent cell background let show
through).

Root cause: `messageLabel.preferredMaxLayoutWidth` was recalculated
inside `layoutSubviews` from `contentView.bounds.width`. In this
environment that value isn't reliably the real table width during
UITableView's `automaticDimension` self-sizing probe — it measured too
small on the pass that matters, and because a multi-line UILabel's
intrinsic (wrapping) size depends entirely on preferredMaxLayoutWidth
(there's no real frame yet to measure against), one bad reading there
cascaded into a permanently too-narrow bubble, every subsequent pass
included, since the "correction" in layoutSubviews only calls
`setNeedsLayout()` — it doesn't invalidate UITableView's already-cached
row height.

Fixed in **ChatMessageCell.swift** and **ChatMessageVc.swift**: the cell
no longer reads its own width from `contentView.bounds`. Its owning VC
now passes `tableView.bounds.width` explicitly into
`configure(with:availableWidth:)` — a value that's unambiguous and
correct from the very first pass — and every width-dependent
calculation (bubble max width, text wrap width, attachment max width)
now derives from that single stored value. `layoutSubviews` still
refines it for later events like rotation, but only once
`contentView.bounds.width` is an actual, sane, already-settled value.

## Post-delivery fix #4 (from the new screenshot)
Two genuinely separate bugs were both visible in the same screenshot —
worth being explicit that they are unrelated to each other:

1. **The "another screen's content visible behind the chat" glitch** —
   this had nothing to do with row heights or cell sizing at all (my
   earlier guess was wrong). Root cause: `viewWillAppear`/
   `viewWillDisappear` were calling `setNavigationBarHidden(_:animated:)`
   with `animated: true` at the same moment the push/pop transition
   itself was animating — a well-known way to leave a stray transition
   snapshot of the previous screen stuck in the view hierarchy, because
   two animations end up racing over the same view. Fixed in
   **ChatMessageVc.swift**: both calls now pass `animated: false`, so
   hiding/showing the bar never fights the navigation transition for it.
   Also gave `tableView` an opaque background (was `.clear`) as
   defense-in-depth, so nothing behind it could ever show through again
   even in some other edge case.
2. **Text bubbles still wrapping narrowly** — added
   `messageLabel.invalidateIntrinsicContentSize()` right after setting
   `.text` in **ChatMessageCell.swift**, to remove any possibility of a
   reused cell's label wrapping against a stale cached intrinsic size
   instead of the `preferredMaxLayoutWidth` set moments earlier in
   `configure(with:availableWidth:)`. If this is still narrow after a
   **clean rebuild** (Xcode: Product → Clean Build Folder, then run
   again — stale derived-data builds can silently keep old cell code),
   that's the next thing to check, since the width-source logic itself
   (fixed in the previous round) is correct.

## Files unchanged
`ChatAPIService.swift`, `ChatHeaderView.swift`, `ChatSectionBuilder.swift`,
`ChatInputView.swift`, `ChatDate.swift` — no bugs found in the audit that
required touching these; API endpoints/payloads are untouched.

## API assumptions
No backend changes required. `contentType`/`messageType` are still
allowed to be `nil` — media detection falls back to extension sniffing
exactly as before, just hardened against query strings.

## Imports / Info.plist
No new imports or entitlements required (`Kingfisher`, `AVKit`,
`AVFoundation`, `UIKit` — all already in use).
