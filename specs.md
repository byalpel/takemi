Reformatted requirements (English)

Build a macOS-only app named TakeMi (target: latest macOS) that runs in the background and, every day at a fixed time, automatically opens a portrait-oriented capture window to take a front camera portrait photo. The capture view shows the live camera preview and overlays the last saved photo behind it with high transparency to help align the face/eyes consistently. The app provides a menu bar item with actions: Display, Don’t display, and Settings. Settings allow configuring the daily trigger time (daily is mandatory) and the photo storage location (default to ~/Documents/TakeMe). After capturing, the user can accept the photo or retake. The app includes a screen to browse previous photos in chronological order with scroll/swipe navigation.

⸻

Product specifications for code generation (macOS TakeMe)

1) Platform and scope
	•	Platform: macOS only, latest macOS version.
	•	App name: TakeMe.
	•	Primary function: daily scheduled portrait capture + photo archive browsing + later video generation from photos (see Video section).

2) App identity
	•	Provide a macOS app icon asset set for TakeMi.
	•	Bundle identifiers and display name consistent with “TakeMi”.

3) App lifecycle and background behavior
	•	App must be able to run as a background service so it can open itself automatically at the configured time.
	•	On scheduled time, the app must bring up the capture window even if previously hidden.
	•	Menu bar item remains available when app is running.

4) Menu bar (status bar) UI

Create a menu bar item with:
	•	Display: show the main capture window (if hidden) and bring it to front.
	•	Don’t display: hide/close the capture window but keep background service running.
	•	Settings…: open settings window/pane.

5) Main capture window

Initial size and layout
	•	On first show, size window relative to current screen:
	•	Height = 50% of screen height.
	•	Width = 30% of screen width.
	•	Maintain a portrait-friendly aspect (if constraints required, prioritize portrait framing).

Camera behavior
	•	On window open, request camera permission if needed.
	•	Open the front camera and show live preview.
	•	Default view should make the face visible (centered framing; no advanced face tracking required unless needed for stability).

Ghost overlay (alignment aid)
	•	If at least one previous photo exists:
	•	Load the most recent photo.
	•	Display it behind the live preview (or as an overlay layer) with high transparency (user-adjustable optional; default high transparency).
	•	Overlay aligned to the preview so the user can place eyes consistently.

Capture flow
	•	Provide a clear action to take photo.
	•	After capture, show the captured image and offer:
	•	Keep/Save
	•	Retake
	•	Retake discards the candidate capture and returns to live preview.

6) Settings

Daily schedule
	•	Setting: dailyCaptureTime (required).
	•	The cadence is always daily (no weekly/monthly options).
	•	Example: 14:00 local time.
	•	App must schedule the opening of the capture window at that time every day.

Storage location
	•	Setting: photoStorageDirectory.
	•	Default path: ~/Documents/TakeMe.
	•	Allow user to choose a different folder via standard macOS folder picker.
	•	Ensure directory exists; create if missing.

Persistence
	•	Persist settings across restarts (e.g., UserDefaults).
	•	On settings change, reschedule the daily trigger accordingly.

7) Photo storage and naming
	•	Store photos in the selected directory.
	•	Use deterministic naming for chronological sorting, e.g. ISO-like timestamp:
	•	YYYY-MM-DD_HH-mm-ss.jpg (or .heic if preferred).
	•	Save metadata needed for ordering (timestamp derived from filename is sufficient).

8) Photo history / gallery view
	•	Provide an in-app screen/view that shows the list of past photos.
	•	Must allow browsing via:
	•	scrolling through the list, and/or
	•	swiping between photos (trackpad gestures), in a portrait viewer.
	•	Display photos in chronological order (newest-first or oldest-first; choose one and keep consistent).
	•	Selecting a photo shows it larger in a viewer.

9) Video generation (from photos)
	•	App must be able to generate videos from the saved photos.
	•	Minimum spec:
	•	Input: all photos in storage directory (chronological).
	•	Output: a video file (e.g., .mp4) saved to a user-chosen location or a default exports folder.
	•	Frame duration: constant per photo (e.g., 1 frame per day; implement as configurable optional).
	•	Use AVFoundation-based encoding on macOS.

10) Permissions and error handling
	•	Camera permission required:
	•	If denied, show a blocking state explaining camera access is needed and link to macOS privacy settings (implementation detail).
	•	If storage directory is not writable:
	•	Show an error and allow selecting a new folder.
	•	If no previous photo exists:
	•	Ghost overlay is disabled silently.

11) Non-functional requirements
	•	Reliability: scheduled trigger should work daily; app should reschedule on launch.
	•	Performance: preview should be real-time; photo browsing should not stutter for large collections (use lazy loading/caching).
	•	macOS conventions: native UI, menu bar integration, standard file pickers.

12) Deliverables for the code generator
	•	Full macOS project implementing:
	•	Menu bar app + windows (capture, settings, gallery).
	•	Background scheduling.
	•	Camera capture with ghost overlay.
	•	Photo persistence to disk.
	•	Gallery browsing.
	•	Video export pipeline from stored photos.
