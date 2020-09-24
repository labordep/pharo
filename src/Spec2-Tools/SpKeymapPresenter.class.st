"
A `SpKeymapPresenter`  shows a list of all defined keymappings.
It shows a filterable list of keymap shortcuts,  name and categories.
Use the context menu to browse the method that defines the shortcut.
"
Class {
	#name : #SpKeymapPresenter,
	#superclass : #SpPresenter,
	#instVars : [
		'clearFilterButton',
		'filterField',
		'kmTable'
	],
	#category : #'Spec2-Tools-Keymapping'
}

{ #category : #specs }
SpKeymapPresenter class >> defaultSpec [
	<spec>
	^ SpBoxLayout newVertical
		add:
			(SpBoxLayout newHorizontal
				add: #filterField;
				add: #clearFilterButton withConstraints: [ :constraints | constraints width: 25 ])
			withConstraints: [ :constraints | constraints height: self toolbarHeight ];
		add: #kmTable;
		yourself
]

{ #category : #'system menu' }
SpKeymapPresenter class >> keymapBrowserMenuOn: aBuilder [ 
	"I build a menu"
	<worldMenu>
	(aBuilder item: #'Keymap Browser')
		parent: #System;
		order: 4;
		icon: self taskbarIcon;
		action: [ self new openWithSpec ];
		help: 'List all know shortcuts and Keymapping categories.'.
]

{ #category : #accessing }
SpKeymapPresenter class >> taskbarIconName [
	^ #keymapBrowserIcon
]

{ #category : #private }
SpKeymapPresenter >> browseDefinitionOfSelectedShortcut [
	| selection action class selector |
	selection := self kmTable selection selectedItem ifNil: [ ^ self ].
	action := selection realValue keymap action ifNil: [ ^ self ].
	class := action method methodClass.
	selector := action method selector.
	Smalltalk tools browser
		openOnClass: class
		selector: selector
		highlight: selection shortcutName
]

{ #category : #accessing }
SpKeymapPresenter >> clearFilterButton [
	^ clearFilterButton
]

{ #category : #accessing }
SpKeymapPresenter >> clearFilterButton: anObject [
	clearFilterButton := anObject
]

{ #category : #private }
SpKeymapPresenter >> collectAllShortcuts [
	self kmTable items: self shortcuts
]

{ #category : #initialization }
SpKeymapPresenter >> connectPresenters [
	filterField
		whenTextChangedDo: [ :text | 
			clearFilterButton enabled: text isNotEmpty.
			self setFilter: text ].
	clearFilterButton action: [ filterField text: '' ]
]

{ #category : #private }
SpKeymapPresenter >> contextMenu [
	| hasSelection |
	
	hasSelection := self kmTable selection selectedItem notNil.
	^ SpMenuPresenter new 
		addGroup: [ :group | group 
			addItem: [ :item | item 
				name: 'Refresh'; 
				icon: (self iconNamed: #smallUpdateIcon); 
				action: [ self collectAllShortcuts ] ] ];
		addGroup: [ :group | group 
			addItem: [ :item | item 
				name: 'Browse Definition';
				icon: (self iconNamed: #smallSystemBrowserIcon);
				enabled: hasSelection;
				action: [ self browseDefinitionOfSelectedShortcut ] ];
			addItem: [ :item | item 
				name: 'Inspect Action';
				icon: (self iconNamed: #smallInspectItIcon);
				enabled: hasSelection;
				action: [ self inspectActionOfSelectedShortcut ] ] ].

]

{ #category : #accessing }
SpKeymapPresenter >> filterField [
	^ filterField
]

{ #category : #accessing }
SpKeymapPresenter >> filterField: anObject [
	filterField := anObject
]

{ #category : #api }
SpKeymapPresenter >> initialExtent [
	^ 600@300
]

{ #category : #initialization }
SpKeymapPresenter >> initializePresenters [
	kmTable := self newTable.
	kmTable
		addColumn: (SpStringTableColumn title: 'Shortcut' evaluated: [ :aKMShortcutDeclaration | aKMShortcutDeclaration realValue shortcut asString ]);
		addColumn: (SpStringTableColumn title: 'Name' evaluated: #shortcutName);
		addColumn: (SpStringTableColumn title: 'Category' evaluated: #categoryName);
		beResizable;
		contextMenu: [ self contextMenu ].
	filterField := self newTextInput.
	filterField
		removeEntryCompletion;
		placeholder: 'Filter';
		autoAccept: true.
	clearFilterButton := self newButton.
	clearFilterButton
		icon: (self iconNamed: #smallCancelIcon);
		enabled: false.
	self collectAllShortcuts
]

{ #category : #private }
SpKeymapPresenter >> inspectActionOfSelectedShortcut [
	| selection action |
	selection := self kmTable selection selectedItem ifNil: [ ^ self ].
	action := selection realValue keymap ifNil: [ ^ self ].
	action inspect
]

{ #category : #accessing }
SpKeymapPresenter >> kmTable [
	^ kmTable
]

{ #category : #accessing }
SpKeymapPresenter >> kmTable: anObject [
	kmTable := anObject
]

{ #category : #private }
SpKeymapPresenter >> menu: aMenu shifted: aBoolean [
	(aMenu add: 'Refresh' target: self selector: #collectAllShortcuts)
		icon: (self iconNamed: #smallUpdateIcon).
	self kmTable selection selectedItem ifNil: [ ^ aMenu ].
	(aMenu
		add: 'Browse Definition'
		target: self
		selector: #browseDefinitionOfSelectedShortcut)
		icon: (self iconNamed: #smallSystemBrowserIcon).
	(aMenu
		add: 'Inspect Action'
		target: self
		selector: #inspectActionOfSelectedShortcut)
		icon: (self iconNamed: #smallInspectItIcon).
	^ aMenu
]

{ #category : #private }
SpKeymapPresenter >> setFilter: aFilterText [
	aFilterText
		ifEmpty: [ self collectAllShortcuts ]
		ifNotEmpty: [ :filter | 
			self kmTable
				items: (self shortcuts select: [ :shortcut | {shortcut realValue shortcut asString . shortcut shortcutName . shortcut categoryName} anySatisfy: [ :s | s includesSubstring: filter caseSensitive: false ] ]) ]
]

{ #category : #private }
SpKeymapPresenter >> shortcuts [
	| collection |
	collection := OrderedCollection new.
	KMRepository default categories
		do: [ :cat | 
			cat keymaps
				do: [ :keymapping | 
					collection
						add:
							(KMShortcutDeclaration new
								shortcutName: keymapping name;
								categoryName: cat name;
								yourself) ] ].
	^ collection sorted: #categoryName ascending
]

{ #category : #initialization }
SpKeymapPresenter >> title [
	^ 'Keymap Browser'
]