// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-namespaces-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-namespaceprefix-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-usedefaultnamespace-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT Y83 Item and LT Y83 Helper (Y83XpFixtures.al); xmlports 75898-75909, test codeunit 75915
// Probe: an Xml port whose Namespaces property declares prefixes that no element uses (al-runner issue 9423). The reporter's shape:
//   DefaultNamespace, UseDefaultNamespace = true, Namespaces = xsd and xsi, text elements Response > Status, no NamespacePrefix anywhere.
//   Neighbours: one unused prefix; a mix where the root uses one prefix (NamespacePrefix) and the other stays unused; a mix where a child
//   uses one prefix; no DefaultNamespace and no UseDefaultNamespace; DefaultNamespace with UseDefaultNamespace = false; UseDefaultNamespace
//   = true without DefaultNamespace; a text attribute with a prefix as the only user; a field attribute with a prefix as the only user; a
//   table element below the root; UTF-16; the export through an XmlPort variable (SetDestination, Export) and the reporter's line-by-line
//   read; the import of the exported text into a Direction = Both port. Each export: the exact text BC writes.
// Result: OBSERVED BELOW (filled in after the observation).
// BC versions: 27, 28, 29

// Cell 1: one unused prefix, default namespace on the elements.
xmlport 75898 "LT XUP One Unused"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xup:order';
    UseDefaultNamespace = true;
    Namespaces = "xsd" = 'http://www.w3.org/2001/XMLSchema';

    schema
    {
        textelement(Response)
        {
            textelement(Status)
            {
                trigger OnBeforePassVariable()
                begin
                    Status := 'ok';
                end;
            }
        }
    }
}

// Cell 2: the reporter's shape, two unused prefixes.
xmlport 75899 "LT XUP Two Unused"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xup:order';
    UseDefaultNamespace = true;
    Namespaces = "xsd" = 'http://www.w3.org/2001/XMLSchema', "xsi" = 'http://www.w3.org/2001/XMLSchema-instance';

    schema
    {
        textelement(Response)
        {
            textelement(Status)
            {
                trigger OnBeforePassVariable()
                begin
                    Status := 'ok';
                end;
            }
        }
    }
}

// Cell 3: the root uses xsd through NamespacePrefix, xsi stays unused.
xmlport 75900 "LT XUP Mix Root Used"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xup:order';
    UseDefaultNamespace = true;
    Namespaces = "xsd" = 'http://www.w3.org/2001/XMLSchema', "xsi" = 'http://www.w3.org/2001/XMLSchema-instance';

    schema
    {
        textelement(Response)
        {
            NamespacePrefix = 'xsd';
            textelement(Status)
            {
                trigger OnBeforePassVariable()
                begin
                    Status := 'ok';
                end;
            }
        }
    }
}

// Cell 3b: the child uses xsi, xsd stays unused.
xmlport 75901 "LT XUP Mix Child Used"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xup:order';
    UseDefaultNamespace = true;
    Namespaces = "xsd" = 'http://www.w3.org/2001/XMLSchema', "xsi" = 'http://www.w3.org/2001/XMLSchema-instance';

    schema
    {
        textelement(Response)
        {
            textelement(Status)
            {
                NamespacePrefix = 'xsi';
                trigger OnBeforePassVariable()
                begin
                    Status := 'ok';
                end;
            }
        }
    }
}

// Cell 4: unused prefixes, no DefaultNamespace, no UseDefaultNamespace.
xmlport 75902 "LT XUP No Default"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = "xsd" = 'http://www.w3.org/2001/XMLSchema', "xsi" = 'http://www.w3.org/2001/XMLSchema-instance';

    schema
    {
        textelement(Response)
        {
            textelement(Status)
            {
                trigger OnBeforePassVariable()
                begin
                    Status := 'ok';
                end;
            }
        }
    }
}

// Cell 4b: DefaultNamespace with UseDefaultNamespace = false.
xmlport 75903 "LT XUP Dn No Udn"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xup:order';
    UseDefaultNamespace = false;
    Namespaces = "xsd" = 'http://www.w3.org/2001/XMLSchema', "xsi" = 'http://www.w3.org/2001/XMLSchema-instance';

    schema
    {
        textelement(Response)
        {
            textelement(Status)
            {
                trigger OnBeforePassVariable()
                begin
                    Status := 'ok';
                end;
            }
        }
    }
}

// Cell 4c: UseDefaultNamespace = true without DefaultNamespace.
xmlport 75904 "LT XUP Udn No Dn"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    UseDefaultNamespace = true;
    Namespaces = "xsd" = 'http://www.w3.org/2001/XMLSchema', "xsi" = 'http://www.w3.org/2001/XMLSchema-instance';

    schema
    {
        textelement(Response)
        {
            textelement(Status)
            {
                trigger OnBeforePassVariable()
                begin
                    Status := 'ok';
                end;
            }
        }
    }
}

// Cell 5: a text attribute with NamespacePrefix = 'xsi' is the only user of a prefix.
xmlport 75905 "LT XUP Text Attr"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xup:order';
    UseDefaultNamespace = true;
    Namespaces = "xsd" = 'http://www.w3.org/2001/XMLSchema', "xsi" = 'http://www.w3.org/2001/XMLSchema-instance';

    schema
    {
        textelement(Response)
        {
            textattribute(Ver)
            {
                NamespacePrefix = 'xsi';
                trigger OnBeforePassVariable()
                begin
                    Ver := 'v1';
                end;
            }
            textelement(Status)
            {
                trigger OnBeforePassVariable()
                begin
                    Status := 'ok';
                end;
            }
        }
    }
}

// Cell 5b: a field attribute with NamespacePrefix = 'xsi' is the only user of a prefix, no DefaultNamespace.
xmlport 75906 "LT XUP Field Attr"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = "xsd" = 'http://www.w3.org/2001/XMLSchema', "xsi" = 'http://www.w3.org/2001/XMLSchema-instance';

    schema
    {
        textelement(Items)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; Rw.Id) { NamespacePrefix = 'xsi'; }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

// Cell 1b: unused prefixes, a table element with field elements below the root.
xmlport 75907 "LT XUP Table"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xup:order';
    UseDefaultNamespace = true;
    Namespaces = "xsd" = 'http://www.w3.org/2001/XMLSchema', "xsi" = 'http://www.w3.org/2001/XMLSchema-instance';

    schema
    {
        textelement(Items)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

// Cell 2b: the reporter's shape in UTF-16.
xmlport 75908 "LT XUP Two Unused Utf16"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF16;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xup:order';
    UseDefaultNamespace = true;
    Namespaces = "xsd" = 'http://www.w3.org/2001/XMLSchema', "xsi" = 'http://www.w3.org/2001/XMLSchema-instance';

    schema
    {
        textelement(Response)
        {
            textelement(Status)
            {
                trigger OnBeforePassVariable()
                begin
                    Status := 'ok';
                end;
            }
        }
    }
}

// Cell 7: the table shape with Direction = Both, for the import of its own export.
xmlport 75909 "LT XUP Both"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xup:order';
    UseDefaultNamespace = true;
    Namespaces = "xsd" = 'http://www.w3.org/2001/XMLSchema', "xsi" = 'http://www.w3.org/2001/XMLSchema-instance';

    schema
    {
        textelement(Items)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

codeunit 75915 "LT XUP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y83 Helper";

    [Test]
    procedure XUP_OneUnused_Export()
    begin
        Observer.Observe('export', Helper.TryExportRaw(Xmlport::"LT XUP One Unused", TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUP_TwoUnused_Export()
    begin
        Observer.Observe('export', Helper.TryExportRaw(Xmlport::"LT XUP Two Unused", TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUP_TwoUnused_ReadByLine()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        // The reporter's export and read: Xmlport.Export into a UTF-8 OutStream, lines read back with ReadText and joined without separator.
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xmlport.Export(Xmlport::"LT XUP Two Unused", OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line;
        end;
        Observer.Observe('read by line', Result);
        Observer.Finish();
    end;

    [Test]
    procedure XUP_TwoUnused_InstanceExport()
    var
        Port: XmlPort "LT XUP Two Unused";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Big: BigText;
        Result: Text;
    begin
        // The export through an XmlPort variable: SetDestination, then Export.
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Big.Read(InS);
        if Big.Length() > 0 then
            Big.GetSubText(Result, 1, Big.Length());
        Observer.Observe('instance export', Result);
        Observer.Finish();
    end;

    [Test]
    procedure XUP_MixRootUsed_Export()
    begin
        Observer.Observe('export', Helper.TryExportRaw(Xmlport::"LT XUP Mix Root Used", TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUP_MixChildUsed_Export()
    begin
        Observer.Observe('export', Helper.TryExportRaw(Xmlport::"LT XUP Mix Child Used", TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUP_NoDefault_Export()
    begin
        Observer.Observe('export', Helper.TryExportRaw(Xmlport::"LT XUP No Default", TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUP_DnNoUdn_Export()
    begin
        Observer.Observe('export', Helper.TryExportRaw(Xmlport::"LT XUP Dn No Udn", TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUP_UdnNoDn_Export()
    begin
        Observer.Observe('export', Helper.TryExportRaw(Xmlport::"LT XUP Udn No Dn", TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUP_TextAttr_Export()
    begin
        Observer.Observe('export', Helper.TryExportRaw(Xmlport::"LT XUP Text Attr", TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUP_FieldAttr_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(Xmlport::"LT XUP Field Attr", TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUP_Table_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(Xmlport::"LT XUP Table", TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUP_TwoUnusedUtf16_Export()
    begin
        Observer.Observe('export', Helper.TryExportRaw(Xmlport::"LT XUP Two Unused Utf16", TextEncoding::UTF16));
        Observer.Finish();
    end;

    [Test]
    procedure XUP_Both_ExportImport()
    var
        Exported: Text;
    begin
        Helper.Seed();
        Exported := Helper.TryExportRaw(Xmlport::"LT XUP Both", TextEncoding::UTF8);
        Observer.Observe('export', Exported);
        Helper.DeleteAll();
        Commit();
        Observer.Observe('import own export', Helper.TryImport(Xmlport::"LT XUP Both", Exported, false));
        Observer.Observe('rows after import', Helper.Rows());
        Helper.DeleteAll();
        Commit();
        Observer.Observe('import plain', Helper.TryImport(Xmlport::"LT XUP Both", '<Items><Item Id="7"><Name>seven</Name></Item></Items>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Observer.Finish();
    end;
}
