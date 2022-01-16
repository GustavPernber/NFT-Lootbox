
// console.log(imgUpload)

// imgUpload.onChange = ()=>{
//     console.log('lol')
// }
// =>{
//     console.log('change')
// }


function change(e){
    let reader= new FileReader()

    let id= parseInt(e.target.id)

    let imgPath=`figure > img#img${id}`
    console.log(imgPath)
    reader.onload=()=>{
        let output=document.querySelector(imgPath)
        output.src=reader.result
    }
    reader.readAsDataURL(e.target.files[0])
    
}