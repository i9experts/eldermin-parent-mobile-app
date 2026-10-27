/// Hosts whose images the app may fetch from inside admin-authored rich text (consent bodies and attachments). Anything else is shown as a
/// plain "Image" link and never loaded, so an admin-chosen server can't learn a parent's IP address / device.
///
/// This is the production upload bucket: the backend (eldermin-backend upload.service.ts) builds URLs as
/// `https://<AWS_S3_BUCKET>.s3.<AWS_REGION>.amazonaws.com/<schoolSlug>/<folder>/<uuid><ext>`, here bucket `eldermin-files-prod1`, region
/// `ap-south-1`. The bucket is public-read, so plain https URLs load without signing.
///
/// The app has no dev / staging flavors (only `--dart-define=API_BASE_URL`), so there is one list and no other environment host is known in
/// this repo. A build pointed at a different backend shows consent images as links until its bucket host is added here.
const List<String> kConsentImageHosts = ['eldermin-files-prod1.s3.ap-south-1.amazonaws.com'];
