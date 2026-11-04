Unit FormImageViewer;

{$mode objfpc}{$H+}

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls, EditBtn, ActnList,
  StdCtrls, Buttons, Menus, FrameImageGrid, FrameImageViewer, FormMain, IniFiles;

Type

  { TfrmImageViewer }

  TfrmImageViewer = Class(TFormMain)
    actCopyFolder: TAction;
    actDeleteFolder: TAction;
    actAddDestFolder: TAction;
    actMoveFolder: TAction;
    actTogglePane: TAction;
    actOpenFolder: TAction;
    actRenameFolder: TAction;
    ActionList1: TActionList;
    cboDestination: TComboBox;
    edtFolder: TDirectoryEdit;
    Label1: TLabel;
    Label2: TLabel;
    lvFolders: TListView;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    mnuView: TMenuItem;
    mnuEdit: TMenuItem;
    pnlImageViewer: TPanel;
    pnlImages: TPanel;
    pnlFolders: TPanel;
    dlgDestination: TSelectDirectoryDialog;
    Splitter1: TSplitter;
    splPreview: TSplitter;
    ToolBar1: TToolBar;
    btnRenameFolder: TToolButton;
    ToolButton1: TToolButton;
    ToolButton10: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    Procedure actAddDestFolderExecute(Sender: TObject);
    Procedure actCopyFolderExecute(Sender: TObject);
    Procedure actDeleteFolderExecute(Sender: TObject);
    Procedure actMoveFolderExecute(Sender: TObject);
    Procedure actOpenFolderExecute(Sender: TObject);
    Procedure actRenameFolderClick(Sender: TObject);
    Procedure actTogglePaneExecute(Sender: TObject);
    Procedure edtFolderChange(Sender: TObject);
    Procedure lvFoldersSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    Procedure GridSelectImage(Sender: TObject; AFilename: String);

    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
  Private
    fmeImageGrid: TFrameImageGrid;
    fmeImageViewer: TFrameImageViewer;

    Procedure LoadFolder(Const AFolder: String);
    Procedure LoadFolders(Const AFolder: String);
  Protected
    Procedure RefreshUI; Override;

    // Stored in %localappdata% - Recommended for persisting user UI preferences
    Procedure LoadLocalSettings(oInifile: TIniFile); Override;
    Procedure SaveLocalSettings(oInifile: TIniFile); Override;

  Public

  End;

Var
  frmImageViewer: TfrmImageViewer;

Implementation

Uses
  FileUtil, FileSupport, LazLogger, LoggingSupport, Clipbrd, Math, OSSupport;

  {$R *.lfm}

  { TfrmImageViewer }

Procedure TfrmImageViewer.FormCreate(Sender: TObject);
Begin
  fmeImageGrid := TFrameImageGrid.Create(pnlImages);
  fmeImageGrid.Parent := pnlImages;
  fmeImageGrid.Align := alClient;
  fmeImageGrid.OnSelectImage := @GridSelectImage;

  fmeImageViewer := TFrameImageViewer.Create(pnlImageViewer);
  fmeImageViewer.Parent := pnlImageViewer;
  fmeImageViewer.Align := alClient;
End;

Procedure TfrmImageViewer.FormDestroy(Sender: TObject);
Begin
  FreeAndNil(fmeImageGrid);
  FreeAndNil(fmeImageViewer);
End;

Procedure TfrmImageViewer.GridSelectImage(Sender: TObject; AFilename: String);
Begin
  If FileExists(AFilename) Then
    fmeImageViewer.Filename := AFilename;
End;

Procedure TfrmImageViewer.lvFoldersSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
Var
  sNewFolder: String;
Begin
  If Selected Then
  Begin
    sNewFolder := IncludeTrailingPathDelimiter(edtFolder.Directory) + Item.Caption;

    LoadFolder(sNewFolder);
  End;

  RefreshUI;
End;

Procedure TfrmImageViewer.edtFolderChange(Sender: TObject);
Begin
  edtFolder.TextHint := edtFolder.Directory;
  LoadFolders(edtFolder.Directory);

  RefreshUI;
End;

Procedure TfrmImageViewer.actRenameFolderClick(Sender: TObject);
Var
  sFolder, sNewFolder, sBase, sMessage: String;
Begin
  If Not Assigned(lvFolders.Selected) Then
    Exit;

  sBase := IncludeTrailingPathDelimiter(edtFolder.Directory);
  sFolder := lvFolders.Selected.Caption;

  sNewFolder := InputBox('Rename Folder', 'New name', sFolder);

  sNewFolder := MakeFilenameSafe(sNewFolder);

  If (sNewFolder <> '') And (sNewFolder <> sFolder) Then
    If Not DirectoryExists(sBase + sNewFolder) Then
    Begin
      If SysUtils.RenameFile(sBase + sFolder, sBase + sNewFolder) Then
      Begin
        lvFolders.Selected.Caption := sNewFolder;

        LoadFolder(sBase + sNewFolder);
      End
      Else
      Begin
        sMessage := 'Unable to rename ' + sFolder;
        ShowMessage(sMessage);
      End;
    End;
End;

Procedure TfrmImageViewer.actTogglePaneExecute(Sender: TObject);
Begin
  If pnlImageViewer.Align = alBottom Then
  Begin
    pnlImageViewer.Align := alRight;
    pnlImageViewer.Width := pnlImages.Width Div 2;

    splPreview.Align := alRight;
    splPreview.Left := pnlImageViewer.Left - splPreview.Width;
  End
  Else
  Begin
    pnlImageViewer.Align := alBottom;
    pnlImageViewer.Height := pnlImages.Height Div 2;

    splPreview.Align := alBottom;
    splPreview.Left := pnlImageViewer.Top - splPreview.Height;
  End;
End;

Procedure TfrmImageViewer.actCopyFolderExecute(Sender: TObject);
Var
  sBase, sFolder: String;
Begin
  If Not Assigned(lvFolders.Selected) Then
    Exit;

  sBase := IncludeTrailingPathDelimiter(edtFolder.Directory);
  sFolder := lvFolders.Selected.Caption;

  Clipboard.Clear;
  Clipboard.AsText := sBase + sFolder;
End;

Procedure TfrmImageViewer.actAddDestFolderExecute(Sender: TObject);
Begin
  dlgDestination.InitialDir := cboDestination.Text;
  If (dlgDestination.Execute) And (dlgDestination.Filename <> cboDestination.Text) Then
  Begin
    // Don't add to history
    //cboDestination.Items.Add(dlgDestination.Filename);

    cboDestination.Text := dlgDestination.Filename;
  End;
End;

Procedure TfrmImageViewer.actDeleteFolderExecute(Sender: TObject);
Var
  sBase, sFolder: String;
  iIndex: Integer;
Begin
  If Not Assigned(lvFolders.Selected) Then
    Exit;

  sBase := IncludeTrailingPathDelimiter(edtFolder.Directory);
  sFolder := lvFolders.Selected.Caption;
  iIndex := lvFolders.Selected.Index;

  If QuestionDlg('Delete Folder', 'Are you sure you wish to delete this folder and all contents?' +
    LineEnding + sFolder, mtConfirmation, [mrYes, mrNo], 0) = mrYes Then
  Begin
    If DeleteDirectoryEx(sBase + sFolder) Then
    Begin
      lvFolders.Items.Delete(iIndex);

      If lvFolders.Items.Count > 0 Then
      Begin
        iIndex := Min(iIndex, lvFolders.Items.Count - 1);

        lvFolders.Selected := lvFolders.Items[iIndex];
        lvFolders.Selected.MakeVisible(False);
      End;
    End;
  End;
End;


Procedure TfrmImageViewer.actMoveFolderExecute(Sender: TObject);
Var
  sBase, sFolder, sDestinationFolder, sSource, sTarget: String;
  iIndex: Integer;
Begin
  If Not Assigned(lvFolders.Selected) Then
    Exit;

  sDestinationFolder := cboDestination.Text;

  If Not DirectoryExists(sDestinationFolder) Then
    Exit;

  sBase := IncludeTrailingPathDelimiter(edtFolder.Directory);
  sFolder := lvFolders.Selected.Caption;
  iIndex := lvFolders.Selected.Index;

  sSource := sBase + sFolder;
  sTarget := IncludeTrailingPathDelimiter(sDestinationFolder) + sFolder;

  // Don't overwrite an existing destination
  If DirectoryExists(sTarget) Then
  Begin
    ShowMessage('Destination folder already exists: ' + sTarget);
    Exit;
  End;

  // Move the entire directory
  If SysUtils.RenameFile(sSource, sTarget) Then
  Begin
    // Remove the moved folder from the list
    lvFolders.Items.Delete(iIndex);

    // Select the same index, or previous if at end
    If lvFolders.Items.Count > 0 Then
    Begin
      If iIndex >= lvFolders.Items.Count Then
        iIndex := lvFolders.Items.Count - 1;

      lvFolders.Selected := lvFolders.Items[iIndex];
    End;
  End
  Else
    ShowMessage('Unable to move folder: ' + sFolder);

  RefreshUI;
End;


Procedure TfrmImageViewer.actOpenFolderExecute(Sender: TObject);
Var
  sBase, sFolder: String;
Begin
  If Not Assigned(lvFolders.Selected) Then
    Exit;

  sBase := IncludeTrailingPathDelimiter(edtFolder.Directory);
  sFolder := lvFolders.Selected.Caption;

  LaunchFile('explorer.exe', Format('/e,"%s"', [sBase + sFolder]));
End;

Procedure TfrmImageViewer.LoadFolders(Const AFolder: String);
Var
  oSearchRec: TSearchRec;
  sFolder: String;
Begin
  {$IFNDEF RELEASE}
  DebugLn([ClassName, '.', {$I %CURRENTROUTINE%}, ' start']);
  {$ENDIF}

  Busy := True;
  lvFolders.Items.BeginUpdate;
  Try
    lvFolders.Items.Clear;

    sFolder := IncludeTrailingPathDelimiter(AFolder);

    If FindFirst(sFolder + '*', faDirectory, oSearchRec) = 0 Then
    Try
      Repeat
        If ((oSearchRec.Attr And faDirectory) <> 0) And (oSearchRec.Name <> '.') And
          (oSearchRec.Name <> '..') Then
          lvFolders.Items.Add.Caption := oSearchRec.Name;
      Until FindNext(oSearchRec) <> 0;
    Finally
      FindClose(oSearchRec);
    End;

  Finally
    lvFolders.Items.EndUpdate;
    Busy := False;

    If lvFolders.Items.Count > 0 Then
      lvFolders.Selected := lvFolders.Items[0];
  End;

  RefreshUI;

  {$IFNDEF RELEASE}
  DebugLn([ClassName, '.', {$I %CURRENTROUTINE%}, ' end']);
  {$ENDIF}
End;

Procedure TfrmImageViewer.RefreshUI;
Var
  bSelected, bExists: Boolean;
  sTemp: String;
Begin
  Inherited RefreshUI;

  bSelected := Assigned(lvFolders.Selected);

  If bSelected Then
  Begin
    sTemp := IncludeTrailingPathDelimiter(edtFolder.Directory) + lvFolders.Selected.Caption;
    bExists := DirectoryExists(sTemp);
  End;

  actRenameFolder.Enabled := bExists;
  actDeleteFolder.Enabled := bExists;
  actOpenFolder.Enabled := bExists;
  actCopyFolder.Enabled := bSelected;
  actMoveFolder.Enabled := bExists And DirectoryExists(cboDestination.Text);
End;

Procedure TfrmImageViewer.LoadLocalSettings(oInifile: TIniFile);
Var
  sTemp: String;
Begin
  Inherited LoadLocalSettings(oInifile);

  // Restore panel alignment and appropriate dimension
  sTemp := oInifile.ReadString('Settings', 'ImageViewerAlign', 'Bottom');

  If SameText(sTemp, 'Right') Then
  Begin
    pnlImageViewer.Align := alRight;
    pnlImageViewer.Width := oInifile.ReadInteger('Settings', 'ImageViewerWidth',
      pnlImageViewer.Width);

    splPreview.Align := alRight;
    splPreview.Left := pnlImageViewer.Left - splPreview.Width;
  End
  Else
  Begin
    pnlImageViewer.Align := alBottom;
    pnlImageViewer.Height := oInifile.ReadInteger('Settings', 'ImageViewerHeight',
      pnlImageViewer.Height);

    splPreview.Align := alBottom;
    splPreview.Top := pnlImageViewer.Top - splPreview.Height;
  End;

  sTemp := oInifile.ReadString('Settings', 'Folder', edtFolder.Directory);

  If DirectoryExists(sTemp) Then
  Begin
    edtFolder.Directory := sTemp;
    edtFolder.TextHint := edtFolder.Directory;
    LoadFolders(sTemp);
  End;

  // Default Destinations
  cboDestination.Items.Clear;
  cboDestination.Items.Add('P:\Personal\Pictures\Art\By Artist\Emily Thompson');
  cboDestination.Items.Add('P:\Personal\Pictures\Holidays');
  cboDestination.Items.Add('P:\Personal\Pictures\Family');
  cboDestination.Items.Add('P:\Personal\Pictures\Friends');
  cboDestination.Items.Add('P:\Personal\Pictures\Misc Personal');

  cboDestination.Items.QuoteChar := '"';
  cboDestination.Items.Delimiter := ',';
  cboDestination.Items.StrictDelimiter := True;

  cboDestination.Items.DelimitedText :=
    oInifile.ReadString('Settings', 'Destinations', cboDestination.Items.DelimitedText);
  cboDestination.Text := oInifile.ReadString('Settings', 'LastDestinations', '');

  RefreshUI;
End;

Procedure TfrmImageViewer.SaveLocalSettings(oInifile: TIniFile);
Begin
  Inherited SaveLocalSettings(oInifile);

  oInifile.WriteString('Settings', 'Folder', edtFolder.Directory);
  oInifile.WriteString('Settings', 'Destinations', cboDestination.Items.DelimitedText);
  oInifile.WriteString('Settings', 'LastDestinations', cboDestination.Text);

  If pnlImageViewer.Align = alRight Then
  Begin
    oInifile.WriteString('Settings', 'ImageViewerAlign', 'Right');
    oInifile.WriteInteger('Settings', 'ImageViewerWidth', pnlImageViewer.Width);
  End
  Else
  Begin
    oInifile.WriteString('Settings', 'ImageViewerAlign', 'Bottom');
    oInifile.WriteInteger('Settings', 'ImageViewerHeight', pnlImageViewer.Height);
  End;
End;

Procedure TfrmImageViewer.LoadFolder(Const AFolder: String);
Var
  slImages: TStringList;
  sImageFile, sExt, sMask: String;
Begin
  {$IFNDEF RELEASE}
  DebugLn([ClassName, '.', {$I %CURRENTROUTINE%}, ' start']);
  {$ENDIF}

  fmeImageGrid.BeginUpdate;
  fmeImageGrid.ClearImages;
  fmeImageViewer.Filename := '';
  Busy := True;
  Try
    slImages := TStringList.Create;
    Try
      sMask := '*.*';

      FindAllFiles(slImages, AFolder, sMask, False);

      slImages.Sorted := True;

      For sImageFile In slImages Do
      Begin
        sExt := ExtractFileExt(sImageFile);

        If IsImage(sExt) Then
          fmeImageGrid.AddImage(sImageFile, ExtractFileName(sImageFile));
      End;
    Finally
      slImages.Free;
    End;
  Finally
    fmeImageGrid.EndUpdate;
    Busy := False;
  End;

  {$IFNDEF RELEASE}
  DebugLn([ClassName, '.', {$I %CURRENTROUTINE%}, ' end']);
  {$ENDIF}
End;

End.
