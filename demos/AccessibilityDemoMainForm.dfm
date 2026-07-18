object AccessibilityDemoMainForm: TAccessibilityDemoMainForm
  Left = 0
  Top = 0
  Caption = 'Accessibility Framework Demo'
  ClientHeight = 760
  ClientWidth = 1220
  Color = clWindow
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  Scaled = True
  ShowHint = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 17
  object SplitterFilters: TSplitter
    Left = 320
    Top = 104
    Width = 6
    Height = 634
    ExplicitHeight = 617
  end
  object SplitterInspector: TSplitter
    Left = 912
    Top = 104
    Width = 6
    Height = 634
    Align = alRight
    ExplicitLeft = 914
    ExplicitHeight = 617
  end
  object pnlCommandBar: TPanel
    Left = 0
    Top = 0
    Width = 1220
    Height = 72
    Align = alTop
    BevelOuter = bvNone
    Caption = ''
    Color = clBtnFace
    ParentBackground = False
    Padding.Left = 16
    Padding.Top = 8
    Padding.Right = 16
    Padding.Bottom = 8
    TabOrder = 0
    object lblCommandTitle: TLabel
      AlignWithMargins = True
      Left = 19
      Top = 11
      Width = 221
      Height = 50
      Align = alLeft
      Caption = 'Complex accessibility demo'
      Hint = 'Complex accessibility demo'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
      ShowHint = True
      ExplicitHeight = 25
    end
    object pnlActions: TFlowPanel
      AlignWithMargins = True
      Left = 252
      Top = 8
      Width = 949
      Height = 56
      Margins.Left = 12
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alClient
      BevelOuter = bvNone
      Caption = ''
      FlowStyle = fsLeftRightTopBottom
      Padding.Left = 4
      Padding.Top = 8
      Padding.Right = 4
      Padding.Bottom = 8
      ShowHint = True
      TabOrder = 0
      object chkAccessibilityEnabled: TCheckBox
        Left = 4
        Top = 14
        Width = 164
        Height = 24
        Caption = 'Accessibility enabled'
        Checked = True
        Hint = 'Enable or disable the accessibility framework for this demo application'
        State = cbChecked
        TabOrder = 0
        OnClick = chkAccessibilityEnabledClick
      end
      object btnNewWindow: TSpeedButton
        Left = 168
        Top = 8
        Width = 128
        Height = 36
        Caption = 'New Window'
        Flat = True
        Hint = 'Create another demo form; it should be discovered by the application-wide manager'
        OnClick = btnNewWindowClick
      end
      object btnRefresh: TSpeedButton
        Left = 296
        Top = 8
        Width = 96
        Height = 36
        Caption = 'Refresh'
        Flat = True
        Hint = 'Refresh all grid and event data'
        OnClick = btnRefreshClick
      end
      object btnSave: TSpeedButton
        Left = 392
        Top = 8
        Width = 88
        Height = 36
        Caption = 'Save'
        Flat = True
        Hint = 'Simulate saving the current demo state'
        OnClick = btnSaveClick
      end
      object btnShowBalloon: TSpeedButton
        Left = 480
        Top = 8
        Width = 120
        Height = 36
        Caption = 'Balloon'
        Flat = True
        Hint = 'Show a balloon hint notification'
        OnClick = btnShowBalloonClick
      end
      object btnShowRegularHint: TButton
        Left = 600
        Top = 8
        Width = 120
        Height = 36
        Caption = 'Regular Hint'
        Hint = 'Regular hint|This is a standard VCL hint raised through Application.OnShowHint'
        ShowHint = True
        TabOrder = 1
        OnClick = btnShowRegularHintClick
      end
      object btnGlyphInfo: TSpeedButton
        Left = 720
        Top = 8
        Width = 44
        Height = 36
        Flat = True
        Glyph.Data = {
          36030000424D3603000000000000360000002800000010000000100000000100
          18000000000000030000C40E0000C40E00000000000000000000464646464646
          4646464646464646464646464646464646464646464646464646464646464646
          46464646464646464646464646D27D28D27D28D27D28FFAA55D27D28D27D28D2
          7D28D27D28FFAA55D27D28D27D28D27D28D27D28FFAA55464646464646D27D28
          D27D28FFAA55D27D28D27D28D27D28D27D28FFAA55D27D28D27D28D27D28D27D
          28FFAA55D27D28464646464646D27D28FFAA55D27D28D27D28D27D28D27D28FF
          AA55D27D28D27D28D27D28D27D28FFAA55D27D28D27D28464646464646FFAA55
          D27D28D27D28D27D28D27D28FFAA55D27D28D27D28D27D28D27D28FFAA55D27D
          28D27D28D27D28464646464646D27D28D27D28D27D28D27D28FFAA55D27D28D2
          7D28D27D28D27D28FFAA55D27D28D27D28D27D28D27D28464646464646D27D28
          D27D28D27D28FFAA55D27D28D27D28D27D28D27D28FFAA55D27D28D27D28D27D
          28D27D28FFAA55464646464646D27D28D27D28FFAA55D27D28D27D28D27D28D2
          7D28FFAA55D27D28D27D28D27D28D27D28FFAA55D27D28464646464646D27D28
          FFAA55D27D28D27D28D27D28D27D28FFAA55D27D28D27D28D27D28D27D28FFAA
          55D27D28D27D28464646464646FFAA55D27D28D27D28D27D28D27D28FFAA55D2
          7D28D27D28D27D28D27D28FFAA55D27D28D27D28D27D28464646464646D27D28
          D27D28D27D28D27D28FFAA55D27D28D27D28D27D28D27D28FFAA55D27D28D27D
          28D27D28D27D28464646464646D27D28D27D28D27D28FFAA55D27D28D27D28D2
          7D28D27D28FFAA55D27D28D27D28D27D28D27D28FFAA55464646464646D27D28
          D27D28FFAA55D27D28D27D28D27D28D27D28FFAA55D27D28D27D28D27D28D27D
          28FFAA55D27D28464646464646D27D28FFAA55D27D28D27D28D27D28D27D28FF
          AA55D27D28D27D28D27D28D27D28FFAA55D27D28D27D28464646464646FFAA55
          D27D28D27D28D27D28D27D28FFAA55D27D28D27D28D27D28D27D28FFAA55D27D
          28D27D28D27D2846464646464646464646464646464646464646464646464646
          4646464646464646464646464646464646464646464646464646}
        Hint = 'Information glyph button|Glyph speed button information hint'
        ShowHint = True
        OnClick = ToolButtonClick
      end
      object btnGlyphWarn: TSpeedButton
        Left = 764
        Top = 8
        Width = 44
        Height = 36
        Flat = True
        Glyph.Data = {
          36030000424D3603000000000000360000002800000010000000100000000100
          18000000000000030000C40E0000C40E00000000000000000000464646464646
          4646464646464646464646464646464646464646464646464646464646464646
          464646464646464646464646461E96DC1E96DC1E96DC4BC3FF1E96DC1E96DC1E
          96DC1E96DC4BC3FF1E96DC1E96DC1E96DC1E96DC4BC3FF4646464646461E96DC
          1E96DC4BC3FF1E96DC1E96DC1E96DC1E96DC4BC3FF1E96DC1E96DC1E96DC1E96
          DC4BC3FF1E96DC4646464646461E96DC4BC3FF1E96DC1E96DC1E96DC1E96DC4B
          C3FF1E96DC1E96DC1E96DC1E96DC4BC3FF1E96DC1E96DC4646464646464BC3FF
          1E96DC1E96DC1E96DC1E96DC4BC3FF1E96DC1E96DC1E96DC1E96DC4BC3FF1E96
          DC1E96DC1E96DC4646464646461E96DC1E96DC1E96DC1E96DC4BC3FF1E96DC1E
          96DC1E96DC1E96DC4BC3FF1E96DC1E96DC1E96DC1E96DC4646464646461E96DC
          1E96DC1E96DC4BC3FF1E96DC1E96DC1E96DC1E96DC4BC3FF1E96DC1E96DC1E96
          DC1E96DC4BC3FF4646464646461E96DC1E96DC4BC3FF1E96DC1E96DC1E96DC1E
          96DC4BC3FF1E96DC1E96DC1E96DC1E96DC4BC3FF1E96DC4646464646461E96DC
          4BC3FF1E96DC1E96DC1E96DC1E96DC4BC3FF1E96DC1E96DC1E96DC1E96DC4BC3
          FF1E96DC1E96DC4646464646464BC3FF1E96DC1E96DC1E96DC1E96DC4BC3FF1E
          96DC1E96DC1E96DC1E96DC4BC3FF1E96DC1E96DC1E96DC4646464646461E96DC
          1E96DC1E96DC1E96DC4BC3FF1E96DC1E96DC1E96DC1E96DC4BC3FF1E96DC1E96
          DC1E96DC1E96DC4646464646461E96DC1E96DC1E96DC4BC3FF1E96DC1E96DC1E
          96DC1E96DC4BC3FF1E96DC1E96DC1E96DC1E96DC4BC3FF4646464646461E96DC
          1E96DC4BC3FF1E96DC1E96DC1E96DC1E96DC4BC3FF1E96DC1E96DC1E96DC1E96
          DC4BC3FF1E96DC4646464646461E96DC4BC3FF1E96DC1E96DC1E96DC1E96DC4B
          C3FF1E96DC1E96DC1E96DC1E96DC4BC3FF1E96DC1E96DC4646464646464BC3FF
          1E96DC1E96DC1E96DC1E96DC4BC3FF1E96DC1E96DC1E96DC1E96DC4BC3FF1E96
          DC1E96DC1E96DC46464646464646464646464646464646464646464646464646
          4646464646464646464646464646464646464646464646464646}
        Hint = 'Warning glyph button|Glyph speed button warning hint'
        ShowHint = True
        OnClick = ToolButtonClick
      end
      object btnToggleDetails: TSpeedButton
        Left = 808
        Top = 8
        Width = 128
        Height = 36
        Caption = 'Details'
        Flat = True
        Hint = 'Show or hide the inspector panel'
        OnClick = btnToggleDetailsClick
      end
    end
  end
  object ToolBar: TToolBar
    Left = 0
    Top = 72
    Width = 1220
    Height = 32
    ButtonHeight = 30
    ButtonWidth = 86
    Caption = 'ToolBar'
    EdgeBorders = []
    List = True
    ShowCaptions = True
    TabOrder = 1
    object ToolButtonOpen: TToolButton
      Left = 0
      Top = 0
      Caption = 'Open'
      Hint = 'Open a record from the toolbar'
      OnClick = ToolButtonClick
    end
    object ToolButtonExport: TToolButton
      Left = 86
      Top = 0
      Caption = 'Export'
      Hint = 'Export the current grid selection'
      OnClick = ToolButtonClick
    end
    object ToolButtonSeparator: TToolButton
      Left = 172
      Top = 0
      Width = 8
      Caption = 'ToolButtonSeparator'
      Style = tbsSeparator
    end
    object ToolButtonAudit: TToolButton
      Left = 180
      Top = 0
      Caption = 'Audit'
      Hint = 'Run an accessibility audit action'
      OnClick = ToolButtonClick
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 738
    Width = 1220
    Height = 22
    Panels = <>
    SimplePanel = True
  end
  object pnlFilters: TPanel
    Left = 0
    Top = 104
    Width = 320
    Height = 634
    Align = alLeft
    BevelOuter = bvNone
    Caption = ''
    Color = clBtnFace
    ParentBackground = False
    Padding.Left = 16
    Padding.Top = 16
    Padding.Right = 16
    Padding.Bottom = 16
    TabOrder = 2
    object lblSearchHelp: TLabel
      AlignWithMargins = True
      Left = 16
      Top = 16
      Width = 288
      Height = 42
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 14
      Align = alTop
      AutoSize = False
      Caption = 'Filter controls use windowed labels; display labels remain TLabel to exercise the framework.'
      WordWrap = True
    end
    object pnlFilterSearchRow: TPanel
      AlignWithMargins = True
      Left = 16
      Top = 72
      Width = 288
      Height = 58
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 12
      Align = alTop
      BevelOuter = bvNone
      Caption = ''
      TabOrder = 0
      object edtSearch: TEdit
        Left = 0
        Top = 29
        Width = 288
        Height = 29
        Align = alBottom
        Hint = 'Search demo orders and audit findings'
        TabOrder = 0
        TextHint = 'customer, order, or finding'
      end
      object StaticTextSearch: TStaticText
        Left = 0
        Top = 0
        Width = 288
        Height = 24
        Align = alTop
        AutoSize = False
        Caption = 'Search text'
        TabStop = False
      end
    end
    object pnlFilterQueueRow: TPanel
      AlignWithMargins = True
      Left = 16
      Top = 142
      Width = 288
      Height = 58
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 12
      Align = alTop
      BevelOuter = bvNone
      Caption = ''
      TabOrder = 1
      object cmbQueue: TComboBox
        Left = 0
        Top = 29
        Width = 288
        Height = 25
        Align = alBottom
        Style = csDropDownList
        Hint = 'Choose the queue represented by the grids'
        TabOrder = 0
        Items.Strings = (
          'All queues'
          'Shipping'
          'Accessibility audit'
          'Manual review')
      end
      object StaticTextQueue: TLabel
        Left = 0
        Top = 0
        Width = 288
        Height = 24
        Align = alTop
        AutoSize = False
        Caption = 'Queue'
        FocusControl = cmbQueue
        Layout = tlCenter
      end
    end
    object pnlFilterLabeledEditRow: TPanel
      AlignWithMargins = True
      Left = 16
      Top = 212
      Width = 288
      Height = 58
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 12
      Align = alTop
      BevelOuter = bvNone
      Caption = ''
      TabOrder = 2
      object labeledEditReference: TLabeledEdit
        Left = 0
        Top = 25
        Width = 288
        Height = 25
        EditLabel.Width = 133
        EditLabel.Height = 17
        EditLabel.Caption = 'TLabeledEdit reference'
        Hint = 'Native TLabeledEdit sample for accessibility comparison'
        TabOrder = 0
        Text = 'REF-1042'
      end
    end
    object pnlFilterOptions: TPanel
      AlignWithMargins = True
      Left = 16
      Top = 282
      Width = 288
      Height = 42
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 12
      Align = alTop
      BevelOuter = bvNone
      Caption = ''
      TabOrder = 3
      object chkIncludeArchived: TCheckBox
        Left = 0
        Top = 8
        Width = 288
        Height = 24
        Caption = 'Include archived rows'
        Hint = 'Includes archived rows in the demo grids'
        TabOrder = 0
      end
    end
    object grpViewMode: TGroupBox
      AlignWithMargins = True
      Left = 16
      Top = 336
      Width = 288
      Height = 86
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 12
      Align = alTop
      Caption = 'View mode'
      Hint = 'Choose how the demo presents detail density'
      TabOrder = 4
      object rbViewCompact: TRadioButton
        Left = 12
        Top = 28
        Width = 120
        Height = 22
        Caption = 'Compact'
        Checked = True
        Hint = 'Use the compact view mode'
        TabOrder = 0
        TabStop = True
      end
      object rbViewDetailed: TRadioButton
        Left = 12
        Top = 54
        Width = 120
        Height = 22
        Caption = 'Detailed'
        Hint = 'Use the detailed view mode'
        TabOrder = 1
      end
    end
    object radioGroupDensity: TRadioGroup
      AlignWithMargins = True
      Left = 16
      Top = 434
      Width = 288
      Height = 80
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 12
      Align = alTop
      Caption = 'Density'
      Hint = 'TRadioGroup sample for role comparison'
      ItemIndex = 0
      Items.Strings = (
        'Comfortable'
        'Compact density')
      TabOrder = 5
    end
    object btnApplyFilters: TButton
      AlignWithMargins = True
      Left = 16
      Top = 526
      Width = 288
      Height = 34
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Apply Filters'
      Default = True
      Hint = 'Apply the selected filters'
      TabOrder = 6
      OnClick = btnApplyFiltersClick
    end
  end
  object pnlInspector: TPanel
    Left = 918
    Top = 104
    Width = 302
    Height = 634
    Align = alRight
    BevelOuter = bvNone
    Caption = ''
    Color = clWindow
    ParentBackground = False
    Padding.Left = 16
    Padding.Top = 16
    Padding.Right = 16
    Padding.Bottom = 16
    TabOrder = 4
    object lblInspectorTitle: TLabel
      AlignWithMargins = True
      Left = 16
      Top = 16
      Width = 270
      Height = 24
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 8
      Align = alTop
      AutoSize = False
      Caption = 'Inspector'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object pnlInspectorMetrics: TPanel
      AlignWithMargins = True
      Left = 16
      Top = 48
      Width = 270
      Height = 104
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 12
      Align = alTop
      BevelOuter = bvNone
      Caption = ''
      TabOrder = 0
      object lblMetricsHeading: TLabel
        Left = 0
        Top = 0
        Width = 270
        Height = 24
        Align = alTop
        AutoSize = False
        Caption = 'Live status labels'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblAuditMetric: TLabel
        AlignWithMargins = True
        Left = 0
        Top = 32
        Width = 270
        Height = 20
        Margins.Left = 0
        Margins.Top = 8
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alTop
        AutoSize = False
        Caption = 'Audit rows: 7'
      end
      object lblSeverityMetric: TLabel
        AlignWithMargins = True
        Left = 0
        Top = 60
        Width = 270
        Height = 20
        Margins.Left = 0
        Margins.Top = 8
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alTop
        AutoSize = False
        Caption = 'High severity checks: 4'
      end
    end
    object pnlInspectorEventsRow: TPanel
      AlignWithMargins = True
      Left = 16
      Top = 164
      Width = 270
      Height = 378
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 12
      Align = alClient
      BevelOuter = bvNone
      Caption = ''
      TabOrder = 1
      object lstEvents: TListBox
        Left = 0
        Top = 28
        Width = 270
        Height = 350
        Align = alClient
        Hint = 'Recent demo events'
        ItemHeight = 17
        TabOrder = 0
      end
      object StaticTextEvents: TStaticText
        Left = 0
        Top = 0
        Width = 270
        Height = 24
        Align = alTop
        AutoSize = False
        Caption = 'Recent events'
        TabStop = False
      end
    end
    object pnlInspectorButtons: TFlowPanel
      Left = 16
      Top = 554
      Width = 270
      Height = 64
      Align = alBottom
      BevelOuter = bvNone
      Caption = ''
      Padding.Top = 14
      TabOrder = 2
      object btnClose: TButton
        Left = 0
        Top = 14
        Width = 112
        Height = 34
        Cancel = True
        Caption = 'Close'
        Hint = 'Close this demo window'
        TabOrder = 0
        OnClick = btnCloseClick
      end
    end
  end
  object pnlClient: TPanel
    Left = 326
    Top = 104
    Width = 586
    Height = 634
    Align = alClient
    BevelOuter = bvNone
    Caption = ''
    Color = clWindow
    ParentBackground = False
    Padding.Left = 16
    Padding.Top = 16
    Padding.Right = 16
    Padding.Bottom = 16
    TabOrder = 3
    object PageControl: TPageControl
      Left = 16
      Top = 16
      Width = 554
      Height = 602
      ActivePage = tabOrders
      Align = alClient
      TabOrder = 0
      object tabOrders: TTabSheet
        Caption = 'TStringGrid rows'
        object pnlOrdersHeader: TPanel
          Left = 0
          Top = 0
          Width = 546
          Height = 56
          Align = alTop
          BevelOuter = bvNone
          Caption = ''
          Padding.Left = 12
          Padding.Top = 8
          Padding.Right = 12
          Padding.Bottom = 8
          TabOrder = 0
          object lblOrdersSummary: TLabel
            Left = 12
            Top = 8
            Width = 522
            Height = 40
            Align = alClient
            AutoSize = False
            Caption = 'TStringGrid row-select keyboard demo. Mouse-over still reads individual cells.'
            Hint = 'TStringGrid row-select keyboard demo'
            Layout = tlCenter
            ShowHint = True
            WordWrap = True
          end
        end
        object StringGridOrders: TStringGrid
          Left = 0
          Top = 56
          Width = 546
          Height = 516
          Align = alClient
          ColCount = 5
          DefaultColWidth = 110
          DefaultRowHeight = 28
          FixedCols = 0
          RowCount = 7
          Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
          TabOrder = 1
        end
      end
      object tabOrderCells: TTabSheet
        Caption = 'TStringGrid cells'
        ImageIndex = 1
        object pnlCellsHeader: TPanel
          Left = 0
          Top = 0
          Width = 546
          Height = 56
          Align = alTop
          BevelOuter = bvNone
          Caption = ''
          Padding.Left = 12
          Padding.Top = 8
          Padding.Right = 12
          Padding.Bottom = 8
          TabOrder = 0
          object lblCellsSummary: TLabel
            Left = 12
            Top = 8
            Width = 522
            Height = 40
            Align = alClient
            AutoSize = False
            Caption = 'TStringGrid cell-select keyboard demo. Arrow keys move between individual cells.'
            Hint = 'TStringGrid cell-select keyboard demo'
            Layout = tlCenter
            ShowHint = True
            WordWrap = True
          end
        end
        object StringGridOrderCells: TStringGrid
          Left = 0
          Top = 56
          Width = 546
          Height = 516
          Align = alClient
          ColCount = 5
          DefaultColWidth = 110
          DefaultRowHeight = 28
          FixedCols = 0
          RowCount = 7
          Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect]
          TabOrder = 1
        end
      end
      object tabTms: TTabSheet
        Caption = 'TAdvStringGrid'
        ImageIndex = 2
        object pnlTmsHeader: TPanel
          Left = 0
          Top = 0
          Width = 546
          Height = 56
          Align = alTop
          BevelOuter = bvNone
          Caption = ''
          Padding.Left = 12
          Padding.Top = 8
          Padding.Right = 12
          Padding.Bottom = 8
          TabOrder = 0
          object lblTmsSummary: TLabel
            Left = 12
            Top = 8
            Width = 522
            Height = 40
            Align = alClient
            AutoSize = False
            Caption = 'TMS TAdvStringGrid uses the opt-in adapter registry passed to Install(Application).'
            WordWrap = True
          end
        end
        object AdvStringGridAudit: TAdvStringGrid
          Left = 0
          Top = 56
          Width = 546
          Height = 516
          Align = alClient
          ColCount = 5
          DefaultColWidth = 118
          DefaultRowHeight = 28
          FixedCols = 1
          RowCount = 8
          TabOrder = 1
        end
      end
      object tabMemoNoWrap: TTabSheet
        Caption = 'Memo no wrap'
        ImageIndex = 3
        object lblDetailsHeading: TLabel
          AlignWithMargins = True
          Left = 16
          Top = 16
          Width = 514
          Height = 25
          Margins.Left = 16
          Margins.Top = 16
          Margins.Right = 16
          Margins.Bottom = 12
          Align = alTop
          Caption = 'Memo without line wrapping'
          Hint = 'Memo without line wrapping'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ShowHint = True
          ExplicitWidth = 254
        end
        object pnlDetailsMemoRow: TPanel
          AlignWithMargins = True
          Left = 16
          Top = 53
          Width = 514
          Height = 503
          Margins.Left = 16
          Margins.Top = 0
          Margins.Right = 16
          Margins.Bottom = 16
          Align = alClient
          BevelOuter = bvNone
          Caption = ''
          TabOrder = 0
          object memoDetailsUnwrapped: TMemo
            Left = 0
            Top = 28
            Width = 514
            Height = 475
            Align = alClient
            Hint = 'Unwrapped notes for memo mouse-over testing'
            Lines.Strings = (
              '')
            ScrollBars = ssVertical
            TabOrder = 0
            WordWrap = False
          end
          object StaticTextDetails: TStaticText
            Left = 0
            Top = 0
            Width = 514
            Height = 24
            Align = alTop
            AutoSize = False
            Caption = 'No-wrap memo notes'
            TabStop = False
          end
        end
      end
      object tabMemoWrap: TTabSheet
        Caption = 'Memo wrap'
        ImageIndex = 4
        object lblWrappedMemoHeading: TLabel
          AlignWithMargins = True
          Left = 16
          Top = 16
          Width = 514
          Height = 25
          Margins.Left = 16
          Margins.Top = 16
          Margins.Right = 16
          Margins.Bottom = 12
          Align = alTop
          Caption = 'Memo with line wrapping'
          Hint = 'Memo with line wrapping'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ShowHint = True
          ExplicitWidth = 235
        end
        object pnlWrappedMemoRow: TPanel
          AlignWithMargins = True
          Left = 16
          Top = 53
          Width = 514
          Height = 503
          Margins.Left = 16
          Margins.Top = 0
          Margins.Right = 16
          Margins.Bottom = 16
          Align = alClient
          BevelOuter = bvNone
          Caption = ''
          TabOrder = 0
          object memoDetailsWrapped: TMemo
            Left = 0
            Top = 28
            Width = 514
            Height = 475
            Align = alClient
            Hint = 'Wrapped notes for memo mouse-over testing'
            Lines.Strings = (
              '')
            ScrollBars = ssVertical
            TabOrder = 0
            WordWrap = True
          end
          object StaticTextDetailsWrapped: TStaticText
            Left = 0
            Top = 0
            Width = 514
            Height = 24
            Align = alTop
            AutoSize = False
            Caption = 'Wrapped memo notes'
            TabStop = False
          end
        end
      end
      object tabDynamicContent: TTabSheet
        Caption = 'Dynamic content'
        ImageIndex = 5
        object pnlDynamicContent: TPanel
          Left = 0
          Top = 0
          Width = 546
          Height = 572
          Align = alClient
          BevelOuter = bvNone
          Caption = ''
          Padding.Left = 20
          Padding.Top = 20
          Padding.Right = 20
          Padding.Bottom = 20
          TabOrder = 0
          object lblDynamicInstructions: TLabel
            AlignWithMargins = True
            Left = 20
            Top = 20
            Width = 506
            Height = 48
            Margins.Left = 0
            Margins.Top = 0
            Margins.Right = 0
            Margins.Bottom = 12
            Align = alTop
            AutoSize = False
            Caption = 'These controls update their text and hints every 10 seconds. Revisit them with NVDA to verify that the current content is exposed.'
            WordWrap = True
          end
          object pnlDynamicStaticTextRow: TPanel
            AlignWithMargins = True
            Left = 20
            Top = 80
            Width = 506
            Height = 44
            Margins.Left = 0
            Margins.Top = 0
            Margins.Right = 0
            Margins.Bottom = 10
            Align = alTop
            BevelOuter = bvNone
            Caption = ''
            TabOrder = 0
            object staticDynamicCaption: TStaticText
              Left = 0
              Top = 0
              Width = 506
              Height = 44
              Align = alClient
              AutoSize = False
              Caption = 'TStaticText caption 0'
              Hint = 'TStaticText hint updated for cycle 0'
              ShowHint = True
              TabStop = False
            end
          end
          object pnlDynamicLabelRow: TPanel
            AlignWithMargins = True
            Left = 20
            Top = 134
            Width = 506
            Height = 44
            Margins.Left = 0
            Margins.Top = 0
            Margins.Right = 0
            Margins.Bottom = 10
            Align = alTop
            BevelOuter = bvNone
            Caption = ''
            TabOrder = 1
            object lblDynamicCaption: TLabel
              Left = 0
              Top = 0
              Width = 506
              Height = 44
              Align = alClient
              AutoSize = False
              Caption = 'TLabel caption 0'
              Hint = 'TLabel hint updated for cycle 0'
              Layout = tlCenter
              ShowHint = True
            end
          end
          object pnlDynamicEditRow: TPanel
            AlignWithMargins = True
            Left = 20
            Top = 188
            Width = 506
            Height = 64
            Margins.Left = 0
            Margins.Top = 0
            Margins.Right = 0
            Margins.Bottom = 10
            Align = alTop
            BevelOuter = bvNone
            Caption = ''
            TabOrder = 2
            object edtDynamicText: TEdit
              Left = 0
              Top = 35
              Width = 506
              Height = 29
              Align = alBottom
              Hint = 'TEdit hint updated for cycle 0'
              ShowHint = True
              TabOrder = 0
              Text = 'TEdit text 0'
            end
            object staticDynamicEditLabel: TStaticText
              Left = 0
              Top = 0
              Width = 506
              Height = 28
              Align = alTop
              AutoSize = False
              Caption = 'Dynamic edit value'
              TabStop = False
            end
          end
          object pnlDynamicButtonRow: TPanel
            AlignWithMargins = True
            Left = 20
            Top = 262
            Width = 506
            Height = 44
            Margins.Left = 0
            Margins.Top = 0
            Margins.Right = 0
            Margins.Bottom = 10
            Align = alTop
            BevelOuter = bvNone
            Caption = ''
            TabOrder = 3
            object btnDynamicCaption: TButton
              Left = 0
              Top = 0
              Width = 240
              Height = 44
              Align = alLeft
              Caption = 'TButton caption 0'
              Hint = 'TButton hint updated for cycle 0'
              ShowHint = True
              TabOrder = 0
            end
          end
          object pnlDynamicBitButtonRow: TPanel
            AlignWithMargins = True
            Left = 20
            Top = 316
            Width = 506
            Height = 44
            Margins.Left = 0
            Margins.Top = 0
            Margins.Right = 0
            Margins.Bottom = 0
            Align = alTop
            BevelOuter = bvNone
            Caption = ''
            TabOrder = 4
            object bitBtnDynamicCaption: TBitBtn
              Left = 0
              Top = 0
              Width = 240
              Height = 44
              Align = alLeft
              Caption = 'TBitBtn caption 0'
              Hint = 'TBitBtn hint updated for cycle 0'
              ShowHint = True
              TabOrder = 0
            end
          end
        end
      end
    end
  end
  object BalloonHint: TBalloonHint
    Left = 584
    Top = 24
  end
  object BalloonHideTimer: TTimer
    Enabled = False
    Interval = 6000
    OnTimer = BalloonHideTimerTimer
    Left = 680
    Top = 24
  end
  object DynamicContentTimer: TTimer
    Interval = 10000
    OnTimer = DynamicContentTimerTimer
    Left = 776
    Top = 24
  end
end
