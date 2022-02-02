var deleteBtn=document.querySelector('button.delete')


let id=parseInt(document.querySelector('form').getAttribute('action').split('/')[3])
let deleteAction=`../../lootbox/${id}/delete`
console.log(deleteAction)

let popupScreen=`
<article class="deletePopup">
<h4>Are you sure you want to delete? <br> This action is irreversible.</h4>
<div> 
<button>No! </button>
<form action="${deleteAction}" method="post">
<input type="submit" value="DELETE">
</form>
</div>
</article>`





deleteBtn.addEventListener('click', ()=>{
    console.log('click')
    document.querySelector('main#edit > section').innerHTML+=popupScreen
    document.querySelector('main#edit').innerHTML+="<div class='grey'></div>"
    
    let noBtn=document.querySelector('.deletePopup > div > button')
    
    noBtn.addEventListener('click', ()=>{
        let elem=document.querySelector('.deletePopup')
        elem.parentNode.removeChild(elem)

        let greyElem=document.querySelector('.grey')
        greyElem.parentNode.removeChild(greyElem)
        location.reload();
        
        
    })
})
