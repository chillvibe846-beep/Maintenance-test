Laptop Audit V3

A reusable PowerShell-based Windows laptop and desktop audit utility.



Documentation note: This README describes the observed V3
workflow. Before publishing a production release, verify the exact
behavior of Laptop_Audit.ps1, especially asset naming, storage
collection, battery collection, and overwrite behavior.



1. Overview

Laptop_Audit.ps1 collects approved technical inventory details from a
Windows computer and creates timestamped reports.


Typical uses:



IT asset inventory

Maintenance records

Hardware verification

Windows documentation

Installed-software inventory

Device handover

Troubleshooting preparation


2. Why Use It?

Manual audits require opening multiple Windows tools and copying
information by hand. This script provides a repeatable process and
consistent report format.


Benefits:



Faster auditing

Less manual typing

Consistent fields

Timestamped reports

Easier device comparison

Separate software inventory

Better maintenance documentation


3. Observed Output

The current V3 run produced:



Main CSV audit report

TXT audit report

Installed-software CSV report


Example report folder:


C:\Users\<username>\OneDrive\Desktop\Laptop_Audit_Reports\

Example filenames:


Laptop_Audit_GEPL-Maintenance_20260915_141118.csv
Laptop_Audit_GEPL-Maintenance_20260915_141118.txt
Installed_Software_GEPL-Maintenance_20260915_141118.csv

4. Information Collected

Depending on the script version, fields may include:


Device identity


Asset name

Windows computer name

Manufacturer

Model

Serial number


Operating system


Windows name

Windows version/build

System type

BIOS mode

Windows/system directory


Firmware


BIOS version

BIOS date

SMBIOS information


Processor and memory


Processor name

CPU cores

Logical processors/threads

CPU speed

Installed RAM


Storage

Verify the actual script before claiming storage coverage. Possible
fields include drive letter, capacity, free space, file system, disk
model, and disk type.


Battery

Battery information is hardware-dependent. A computer may not expose
battery data, and a CIM/WMI provider may fail. A battery query error
does not automatically mean the battery is damaged.


Software

The software CSV may include software name, version, publisher, install
date, and registry source. It should be described as detected
software, not a guaranteed complete inventory, unless thoroughly
tested.


5. Information Not to Collect

Do not collect or export:



Passwords or password hashes

BitLocker recovery keys

Private encryption keys

Browser passwords or cookies

API keys or authentication tokens

SSH private keys

VPN credentials

Wi-Fi passwords

Personal documents, photos, videos, or messages

Banking information

Personal browsing history


This is an inventory tool, not a credential or personal-data collection
tool.


6. Requirements


Windows 10 or Windows 11, if tested and supported

Windows PowerShell

Laptop_Audit.ps1

Permission to audit the device

Writable report folder

Sufficient free disk space

Recommended: Administrator PowerShell


7. Before Running

Authorization


 You own the device or have permission.

 The audit purpose is approved.

 The report recipient is authorized.

 The device belongs to the correct department.


Privacy


 Do not place personal files in the report folder.

 Do not upload real reports to a public GitHub repository.

 Treat serial numbers and computer names as internal information.

 Confirm whether software names are confidential.

 Use approved company storage.

 Redact sensitive identifiers before external sharing.


Technical checks


 Confirm the computer name.

 Confirm the official asset name.

 Confirm the correct user profile.

 Confirm the output folder.

 Confirm the script version.

 Keep a backup of older reports.

 Close Excel files that may lock reports.

 Check available disk space.


8. Installation

Place the script in a local folder, for example:


C:\Users\<username>\Downloads\Laptop_Audit.ps1

Recommended repository structure:


Laptop-Audit-V3/
├── Laptop_Audit.ps1
├── README.md
├── LICENSE
├── CHANGELOG.md
├── SECURITY.md
├── PRIVACY.md
├── .gitignore
├── docs/
└── examples/

Never publish real audit reports. Publish only sanitized examples.


9. How to Run

Open PowerShell, preferably as Administrator.


Move to the script folder

Set-Location "$env:USERPROFILE\Downloads"

Confirm the script exists

Get-ChildItem -Filter "*.ps1"

Expected:


Laptop_Audit.ps1

Run the script

powershell.exe -ExecutionPolicy Bypass -File ".\Laptop_Audit.ps1"

Wait for:


LAPTOP AUDIT COMPLETED

Record the report paths displayed in PowerShell.


Open the report folder

Use the exact folder printed by the script. Example:


explorer.exe "$env:USERPROFILE\OneDrive\Desktop\Laptop_Audit_Reports"

10. Using It on Another Computer

The same script can be reused, but verify whether the asset name is
automatic or hardcoded.


Look for code similar to:


$AssetName = "GEPL-Maintenance"

If present, replace it with a safe configurable value or an approved
automatic naming method.


Do not assume the Windows computer name equals the official company
asset ID.


For every new computer:



Copy the approved script.

Confirm authorization.

Confirm asset name.

Confirm output location.

Run the audit.

Verify manufacturer, model, serial number, and computer name.

Verify software inventory.

Store the report securely.


11. Report Safety

Timestamped names reduce filename collisions, but they do not guarantee
that old reports cannot be overwritten.


Before production use, inspect whether the script uses:



-Force

Export-Csv

Out-File

Set-Content

Add-Content

File deletion

Folder cleanup

Fixed filenames


Recommended rule:



Never delete or overwrite an existing report automatically.



Back up old reports before testing changes.


12. Privacy and Security Policy

Data minimization

Collect only information required for the stated audit purpose.


Confidentiality

Reports may reveal serial numbers, internal computer names,
employee/department naming, installed applications, security tools, and
Windows versions. Store them as internal records.


Public repositories

Add generated reports to .gitignore:


Laptop_Audit_*.csv
Laptop_Audit_*.txt
Installed_Software_*.csv
Laptop_Audit_Reports/
reports/*

Never commit real reports to GitHub.


Redaction

Before external sharing, consider removing:



Serial numbers

Computer names

User names

Asset IDs

Internal paths

Security software names

Confidential application names


Retention

Define how long reports are retained. Delete temporary copies after
verified transfer according to company policy.


13. Responsible Use

Use this tool only for legitimate administration and inventory.


Do not use it to:



Audit unauthorized devices

Monitor employees secretly

Extract credentials

Collect private files

Bypass access controls

Circumvent security protections

Publish internal asset information

Collect unnecessary personal data


The operator is responsible for authorization and report protection.


14. Common Errors

Illegal characters in path

Cause: accidentally pasting the PowerShell prompt or an extra >.


Correct:


Set-Location "$env:USERPROFILE\Downloads"

Do not paste:


PS C:\Users\genli\Downloads>

Cannot find path

Cause: PowerShell is still in C:\Windows\System32.


Fix:


Set-Location "$env:USERPROFILE\Downloads"
Get-Location

Ampersand operator error

Cause: a pasted command contains an accidental & or prompt text.


Use simple commands:


Get-ChildItem -Filter "*.ps1"
powershell.exe -ExecutionPolicy Bypass -File ".\Laptop_Audit.ps1"

Generic failure from Get-CimInstance

This may be caused by unsupported hardware, a missing provider, firmware
limitations, or a WMI/CIM issue. It should not stop the entire audit.
Ideally, the script records Not available and continues.


Script runs but no report appears

Check:


Get-Location
Get-ChildItem -Filter "*.ps1"

Then read the report paths printed at the end. Also check OneDrive sync,
permissions, antivirus quarantine, Excel file locks, and alternate
output folders.


Excel displays

The column is too narrow. Double-click the right edge of the column
header to auto-fit it. Do not overwrite the original CSV unnecessarily.


15. Validation Checklist

Execution


 Completion message appeared.

 No unexpected terminating error occurred.

 Report paths were displayed.

 No unexpected files were created.


Identity


 Asset name is correct.

 Computer name is correct.

 Manufacturer is correct.

 Model is correct.

 Serial number matches the device.


Reports


 Main CSV exists.

 TXT report exists.

 Software CSV exists.

 Timestamp is correct.

 Files open successfully.

 Reports are in the intended folder.


Privacy


 No passwords or recovery keys are present.

 No personal files were collected.

 No real report was published publicly.

 Access is restricted.

 Temporary copies follow retention policy.


16. Recommended Production Improvements

Before calling the project production-ready, consider:



try/catch error handling

Per-section failure handling

Clear exit codes

Diagnostic logging

Configurable asset name

Automatic output-folder creation

Unique filenames

Battery errors treated as non-fatal

UTF-8 output

Schema/version fields

JSON or HTML output

-NoSoftwareInventory option

Privacy notice at startup

Test coverage on laptops and desktops

Windows 10/11 compatibility testing

Standard-user and administrator testing

OneDrive-enabled and OneDrive-disabled testing


17. Limitations

This is an inventory helper, not a complete security scanner, compliance
platform, or hardware diagnostic tool.


It does not automatically prove that:



The device is secure

Windows is fully patched

Antivirus is correctly configured

Disk health is good

Battery health is good

All software is detected

All hardware is detected

The report is suitable for public sharing


Important findings should be verified with approved tools and
procedures.


18. Release Checklist


 Script reviewed by another administrator.

 No credentials or private files are collected.

 Existing reports are not deleted.

 Filenames are unique.

 Asset naming is documented.

 Battery failures are non-fatal.

 README matches the script.

 Privacy and security policies are included.

 Real reports are excluded from Git.

 Version and changelog are updated.

 Tests are documented.

 Release package contains no confidential data.


19. Suggested Repository Files

Laptop-Audit-V3/
├── Laptop_Audit.ps1
├── README.md
├── LICENSE
├── CHANGELOG.md
├── SECURITY.md
├── PRIVACY.md
├── CONTRIBUTING.md
├── .gitignore
├── docs/
│   ├── INSTALLATION.md
│   ├── TROUBLESHOOTING.md
│   ├── REPORT_SCHEMA.md
│   └── RELEASE_CHECKLIST.md
└── examples/
    └── sanitized-report-example.csv

Final Note

The safest audit tool collects the minimum required information, creates
predictable timestamped reports, never deletes existing records, handles
unsupported hardware gracefully, and explains its privacy behavior
clearly.

