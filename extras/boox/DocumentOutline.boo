namespace BooExplorer

import WeifenLuo.WinFormsUI
import System
import System.Windows.Forms
import System.Drawing
import Boo.Lang.Compiler.Ast

class DocumentOutline(Content):
	
	_activeDocument as BooEditor
	_tree as TreeView
	_treeViewVisitor as TreeViewVisitor
	_timer = Timer(Tick: _timer_Tick, Interval: 5s.TotalMilliseconds)
	_module as Module
	
	def constructor():
		_tree = TreeView(Dock: DockStyle.Fill,
						DoubleClick: _tree_DoubleClick)
		_treeViewVisitor = TreeViewVisitor(_tree)
		
		SuspendLayout()
		
		Controls.Add(_tree)
		self.AllowedStates = (
					ContentStates.Float |
					ContentStates.DockLeft |
					ContentStates.DockRight)
		self.ClientSize = System.Drawing.Size(295, 347)
		
		self.DockPadding.Bottom = 2
		self.DockPadding.Top = 26
		self.HideOnClose = true
		self.ShowHint = WeifenLuo.WinFormsUI.DockState.DockRight
		self.Text = "Document Outline"
		ResumeLayout(false)
		
	ActiveDocument as BooEditor:
		set:
			_activeDocument = value
			_timer.Enabled = value is not null
			Update() if self.Visible

	def Update():
		if _activeDocument is null:
			_tree.Nodes.Clear()
		else:
			_activeDocument.UpdateModule()
			UpdateTree(_activeDocument.Module)
	
	def UpdateTree(module as Module):
		if module is not _module:
			_module = module
			_treeViewVisitor.Switch(_module)
		
	def _timer_Tick(sender, args as EventArgs):
		Update()
		
	def _tree_DoubleClick(sender, args as EventArgs):
		return unless _activeDocument
		
		if (treeNode = _tree.SelectedNode):
			node as Node = treeNode.Tag
			if node is not null:
				info = node.LexicalInfo
				_activeDocument.GoTo(info.Line-1)

class TreeViewVisitor(DepthFirstSwitcher):
	
	_tree as TreeView
	_current as TreeNode
	
	def constructor(tree):
		_tree = tree
		
	override def OnModule(node as Module):
		
		if node.Namespace:
			name = node.Namespace.Name
		else:
			name = node.Name

		_current = TreeNode("root")
		Switch(node.Members)
		
		_tree.BeginUpdate()
		_tree.Nodes.Clear()
		if len(_current.Nodes):
			_tree.Nodes.AddRange(tuple(TreeNode, _current.Nodes))
			_tree.ExpandAll()
			_tree.Nodes[0].EnsureVisible()
		_tree.EndUpdate()
		
	override def OnProperty(node as Property):
		Add(node.Name, node)		
		
	override def OnField(node as Field):
		Add(node.Name, node)
		
	override def OnInterfaceDefinition(node as InterfaceDefinition):
		OnTypeDefinition(node)
		
	override def OnClassDefinition(node as ClassDefinition):
		OnTypeDefinition(node)
		
	override def OnEnumDefinition(node as EnumDefinition):
		OnTypeDefinition(node)
		
	def OnTypeDefinition(node as TypeDefinition):
		saved = _current
		
		_current = Add(node.Name, node)
		Switch(node.Members)
		
		_current = saved
		
	override def OnMethod(node as Method):
		name = "${node.Name}(${join([p.Name for p as ParameterDeclaration in node.Parameters], ', ')})"		
		Add(name, node)
		
	def Add(text as string, data):
		node = _current.Nodes.Add(text)
		node.Tag = data
		return node
